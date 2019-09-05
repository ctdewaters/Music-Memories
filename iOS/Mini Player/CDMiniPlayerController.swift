//
//  MiniPlayerViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/28/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer
import MemoriesKit

/// `CDMiniPlayerController`: Provides playback controls for currently playing song.
class CDMiniPlayerController: UIViewController {
    
    ///The window to present the miniplayer in.
    var window: UIWindow? {
        return UIWindow.key
    }
    
    ///The controller's view casted as a `MiniPlayer`.
    var miniPlayer: CDMiniPlayer {
        return self.view as! CDMiniPlayer
    }
    
    ///A pan gesture recognizer which is placed on the mini player to open and close it.
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    ///A long press gesture recognizer which is placed on the mini player to open and close it.
    private var longPressGestureRecognizer: UILongPressGestureRecognizer?
    
    ///A gesture recognizer, for haptic feedback when opening and closing the miniplayer.
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    ///An audio session to retrieve the current route from.
    private let audioSession = AVAudioSession()
    
    ///The shared instance.
    public static let shared = CDMiniPlayerController()
    
    ///A notification that will signal the `MiniPlayerViewController` to change the vertical position of the closed `MiniPlayer`.
    public static let miniPlayerVerticalClosedPositionDidChange = Notification.Name("miniPlayerVerticalClosedPositionDidChange")
    
    //MARK: - Initialization
    init() {
        super.init(nibName: "CDMiniPlayerController", bundle: nil)
        
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.bottomPaddingDidChange(withNotification:)), name: Notification.Name.miniPlayerBottomPaddingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaPlaybackStateChanged), name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaPlaybackItemChanged), name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.audioRouteChanged(withNotification:)), name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    ///Adds the mini player to the application window.
    func setup() {
        self.window?.addSubview(self.miniPlayer)
        //self.miniPlayer.layer.zPosition = .greatestFiniteMagnitude - 1
        
        //Setup gestures.
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.panGestureRecognizer?.delegate = self
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.longPressGestureRecognizer?.minimumPressDuration = 0.0
        self.longPressGestureRecognizer?.delegate = self
        self.miniPlayer.addGestureRecognizer(self.panGestureRecognizer!)
        self.miniPlayer.addGestureRecognizer(self.longPressGestureRecognizer!)
        
        //Update the mini player with the playback state and now playing item.
        let playbackState = MPMusicPlayerController.systemMusicPlayer.playbackState
        self.miniPlayer.update(withState: playbackState == .stopped ? .disabled : .closed, animated: false)
        self.miniPlayer.update(withPlaybackState: playbackState)
        self.miniPlayer.update(withPlaybackRoute: self.audioSession.currentRoute)
                
        guard let nowPlayingItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem else { return }
                
        self.miniPlayer.update(withMediaItem: nowPlayingItem)
    }
    
    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Update shuffle and repeat mode UI.
        self.updateShuffleAndRepeatModeUI()
        
        guard let readableWidth = self.window?.readableContentGuide.layoutFrame.width else { return }
        self.view.frame.size.width = readableWidth
    }
    
    //MARK: - Notification Observer Functions
    @objc private func bottomPaddingDidChange(withNotification notification: Notification) {
        guard let newPadding = notification.userInfo?["padding"] as? CGFloat else { return }
        self.miniPlayer.update(padding: newPadding)
    }
    
    @objc private func mediaPlaybackStateChanged() {
        let playbackState = MPMusicPlayerController.systemMusicPlayer.playbackState
        
        if playbackState == .stopped {
            self.miniPlayer.update(withState: .disabled, animated: true)
        }
        else if self.miniPlayer.state == .disabled {
            self.miniPlayer.update(withState: .closed, animated: true)
        }
        
        self.miniPlayer.update(withPlaybackState: playbackState)
    }
    
    @objc private func mediaPlaybackItemChanged() {
        guard let nowPlayingItem = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem else { return }
        
        self.miniPlayer.update(withMediaItem: nowPlayingItem)
    }
    
    @objc private func audioRouteChanged(withNotification notification: Notification) {
        DispatchQueue.main.async {
            self.miniPlayer.update(withPlaybackRoute: self.audioSession.currentRoute)
        }
    }
    
    @objc private func orientationChanged() {
                
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.miniPlayer.update(withState: self.miniPlayer.state, animated: true)
        }
    }
    
    //MARK: - Updating Shuffle and Repeat Mode
    func updateShuffleAndRepeatModeUI() {
        let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer
        let repeatMode = systemMusicPlayer.repeatMode
        let shuffleMode = systemMusicPlayer.shuffleMode
        
        self.miniPlayer.update(withRepeatMode: repeatMode, andShuffleMode: shuffleMode)
    }
    
    //MARK: - Gestures
    
    private var startingYOrigin: CGFloat?
    private var targetMet = false
    @objc private func handlePan(_ panRecognizer: UIPanGestureRecognizer) {
        guard let startingYOrigin = self.startingYOrigin else {
            self.startingYOrigin = self.miniPlayer.frame.origin.y
            self.targetMet = false
            return
        }
        let state = panRecognizer.state
        let miniPlayerState = self.miniPlayer.state
        let yTranslation = panRecognizer.translation(in: self.miniPlayer).y
        
        let normalizationRange = miniPlayerState == .closed ? (-CGFloat.greatestFiniteMagnitude...0) : (0...CGFloat.greatestFiniteMagnitude)
        let visibleTranslationRange = miniPlayerState == .closed ? (-CGFloat.greatestFiniteMagnitude...25) : (-25...CGFloat.greatestFiniteMagnitude)
        let normalizedYTranslation = normalizationRange.clamp(yTranslation)
        let visibleYTranslation = visibleTranslationRange.clamp(yTranslation)
        let translationTarget: CGFloat = CDMiniPlayer.State.closed.size.height * 1.25
        
        if state == .ended || state == .failed {
            //Reset properties.
            self.startingYOrigin = nil
            self.targetMet = false
            
            //Return to state.
            self.miniPlayer.update(withState: miniPlayerState, animated: true)
            
        }
        else {
            
            UIView.animate(withDuration: 0.15) {
                self.miniPlayer.frame.origin.y = startingYOrigin + visibleYTranslation
            }
            
            //Invalidate the long press recognizer if the pan has translated farther than 2 points.
            if abs(yTranslation) > 2 {
                self.highlight(on: false)
                self.invalidate(recognizer: self.longPressGestureRecognizer!)
            }
            
            if abs(normalizedYTranslation) >= translationTarget && !self.targetMet {
                self.targetMet = true
                //Target reached, toggle miniplayer state.
                let newState: CDMiniPlayer.State = miniPlayerState == .closed ? .open : .closed
                
                //Invalidate the pan gesture recognizer.
                self.invalidate(recognizer: panRecognizer)
                self.startingYOrigin = nil

                self.removeGestures()
                self.miniPlayer.update(withState: newState, animated: true)
                
                //Send impact.
                self.impactGenerator.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.addGestures()
                }
            }
        }
    }
    
    @objc private func handleTap(_ longPressRecognizer: UILongPressGestureRecognizer) {
        let miniPlayerState = self.miniPlayer.state
        let newState: CDMiniPlayer.State = miniPlayerState == .closed ? .open : .closed
        let state = longPressRecognizer.state
        
        //Disable when opened.
        if miniPlayerState == .closed {
            if state == .began {
                self.highlight(on: true)
                return
            }
            
            if state == .ended || state == .failed {
                self.highlight(on: false)
            }
            
            if state == .ended {
                self.removeGestures()
                self.miniPlayer.update(withState: newState, animated: true)
                self.impactGenerator.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.addGestures()
                }
            }
        }
    }
    
    private func invalidate(recognizer: UIGestureRecognizer) {
        recognizer.isEnabled = false
        recognizer.isEnabled = true
    }
    
    private func removeGestures() {
        self.miniPlayer.removeGestureRecognizer(self.panGestureRecognizer!)
        self.miniPlayer.removeGestureRecognizer(self.longPressGestureRecognizer!)
    }
    
    private func addGestures() {
        self.miniPlayer.addGestureRecognizer(self.panGestureRecognizer!)
        self.miniPlayer.addGestureRecognizer(self.longPressGestureRecognizer!)
    }
    
    //MARK: - Highlighting
    func highlight(on: Bool) {
        let effect: UIBlurEffect = on ? UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial) : UIBlurEffect(style: UIBlurEffect.Style.systemThickMaterial)
        
        UIView.animate(withDuration: 0.25) {
            self.miniPlayer.backgroundBlur.effect = effect
        }
    }
}

extension CDMiniPlayerController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: self.miniPlayer.backgroundBlur.contentView)

        if gestureRecognizer == self.longPressGestureRecognizer {
            if self.miniPlayer.state == .open ||  self.miniPlayer.playbackButtonsContainerView.frame.contains(location) {
                return false
            }
        }
            
        return true
    }
}

extension Notification.Name {
    ///A notification that will signal the `MiniPlayerViewController` to change the vertical position of the closed `MiniPlayer`.
    public static let miniPlayerBottomPaddingDidChange = Notification.Name("miniPlayerVerticalClosedPositionDidChange")
}

extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}
