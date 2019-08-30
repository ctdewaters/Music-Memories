//
//  MiniPlayer.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/28/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer
import MarqueeLabel
import AVKit
import DeviceKit

/// `MiniPlayer`: A `UIView` that provides access to seeking and playback controls for the global media player.
class MiniPlayer: UIView {

    //MARK: - Properties
    
    ///The state of the mini player.
    var state: MiniPlayer.State = .disabled
    
    ///The padding below the miniplayer in the `closed` state.
    var bottomPadding: CGFloat = 75.0
    
    ///An overlay view for the underlying views when the mini player is presented.
    private var overlayView: UIView?
    
    ///A volume view to provide volume controls.
    private var volumeView: MPVolumeView?
    
    ///A route picker view to change the audio output.
    private var routePicker: AVRoutePickerView?
    
    //MARK: - IBOutlets
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var trackTitleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var playbackButtonsContainerView: UIView!
    @IBOutlet weak var volumeContainerView: UIView!
    @IBOutlet weak var routeContainerView: UIView!
    @IBOutlet weak var routeLabel: UILabel!
    
    //MARK: - Constraint Outlets
    @IBOutlet weak var artworkLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelsTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelsLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var volumeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsSpacingConstraint1: NSLayoutConstraint!
    @IBOutlet weak var buttonsSpacingConstraint2: NSLayoutConstraint!
    @IBOutlet weak var closeButtonTopConstraint: NSLayoutConstraint!
    
    //MARK: - Update Functions
    
    /// Updates the miniplayer to a given state.
    /// - Parameter state: The state to transition the miniplayer to.
    /// - Parameter animated: If true, the miniplayer will be animated to the given state with a spring animation.
    func update(withState state: MiniPlayer.State, animated: Bool = true) {
        let newSize = state.size
        let newOrigin = state.origin(withBottomPadding: self.bottomPadding)
        let newFrame = CGRect(origin: newOrigin, size: newSize)
                
        //Overlay and volume views.
        if state == .open {
            self.toggleVolumeView(on: true)
            self.presentOverlayView(animated: animated)
        }
        else {
            self.toggleVolumeView(on: false)
            self.dismissOverlayView(animated: animated)
        }
        
        //Constraints.
        self.updateConstraints(withState: state, animated: animated)
        
        ///Update the visual state.
        if animated {
            //Animate
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.25, options: .curveEaseInOut, animations: {
                self.frame = newFrame
                self.layoutIfNeeded()
            }, completion: nil)
        }
        else {
            //Set new values based on state.
            self.frame = newFrame
        }
        self.state = state
    }
    
    /// Updates the bottom padding of the mini player when it is in the `closed` state.
    /// - Parameter padding: The new bottom padding for the mini player in the closed state.
    func update(padding: CGFloat) {
        self.bottomPadding = padding
        
        self.update(withState: self.state, animated: self.state != .disabled)
        
        UIWindow.key?.bringSubviewToFront(self)
    }
    
    /// Updates the play pause button with a given playback state.
    /// - Parameter playbackState: The current playback state of the system music player.
    func update(withPlaybackState playbackState: MPMusicPlaybackState) {
        self.playPauseButton.setImage(playbackState == .playing ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill"), for: .normal)
    }
    
    /// Updates the mini player with a given media item.
    /// - Parameter mediaItem: The currently playing media item to represent in the mini player.
    func update(withMediaItem mediaItem: MPMediaItem) {
        //Artwork
        DispatchQueue.global(qos: .userInteractive).async {
            let artwork = mediaItem.artwork?.image(at: CGSize(width: 400, height: 400)) ?? #imageLiteral(resourceName: "logo500")
            DispatchQueue.main.async {
                self.artwork.image = artwork
            }
        }
        
        //Labels
        self.trackTitleLabel.text = mediaItem.title ?? ""
        
        let artist = mediaItem.artist ?? ""
        let album = mediaItem.albumTitle ?? ""
        self.artistLabel.text = "\(artist) • \(album)"
    }
    
    
    /// Updates the route label with a given route.
    /// - Parameter route: The route who's identifier will be placed in the route label.
    func update(withPlaybackRoute route: AVAudioSessionRouteDescription) {
        guard let output = route.outputs.first else { return }
        
        if output.portType == .builtInSpeaker {
            //Set device idiom as label text.
            self.routeLabel.text = Device().name
        }
        else {
            self.routeLabel.text = output.portName
        }
        
        let labelColor: UIColor = (output.portType == .airPlay || output.portType == .bluetoothA2DP) ? .theme : .systemBlue
        UIView.animate(withDuration: 0.15) {
            self.routeLabel.textColor = labelColor
        }
    }
    
    //MARK: - Overlay View
    private func presentOverlayView(animated: Bool) {
        guard let keyWindow = UIWindow.key else { return }
        if self.overlayView == nil {
            //Initialize the overlay view.
            self.overlayView = UIView(frame: keyWindow.frame)
            self.overlayView?.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            self.overlayView?.alpha = 0
            keyWindow.addSubview(self.overlayView!)
            keyWindow.bringSubviewToFront(self)
        }
        if animated {
            //Animate
            UIView.animate(withDuration: 0.25) {
                self.overlayView?.alpha = 1
            }
        }
        else {
            self.overlayView?.alpha = 1
        }
    }
    
    private func dismissOverlayView(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
                self.overlayView?.alpha = 0
            }) { (complete) in
                if complete {
                    self.overlayView?.removeFromSuperview()
                    self.overlayView = nil
                }
            }
        }
        else {
            self.overlayView?.removeFromSuperview()
            self.overlayView = nil
        }
    }
    
    //MARK: - Volume View
    private func toggleVolumeView(on: Bool) {
        if on {
            if self.volumeView == nil {
                self.volumeView = MPVolumeView(frame: self.volumeContainerView.bounds)
                self.volumeView?.tintColor = .theme
                self.volumeView?.showsRouteButton = false
                                
                //Route picker view.
                self.routePicker = AVRoutePickerView(frame: self.routeContainerView.bounds)
                self.routePicker?.activeTintColor = .theme
            }
            self.volumeContainerView.addSubview(self.volumeView!)
            self.routeContainerView.addSubview(self.routePicker!)
            return
        }
        self.volumeView?.removeFromSuperview()
        self.routePicker?.removeFromSuperview()
    }
    
    //MARK: - Constraints
    private func updateConstraints(withState state: MiniPlayer.State, animated: Bool) {
        //Artwork
        self.artworkTopConstraint.constant = state.artworkTop
        self.artworkWidthConstraint.constant = state.artworkWidth
        self.artworkLeadingConstraint.constant = state.artworkLeading
        
        //Labels
        self.labelsTopConstraint.constant = state.labelsTop
        self.labelsLeadingConstraint.constant = state.labelsLeading
        self.labelsWidthConstraint.constant = state.labelsWidth
        let textAlignment = state.labelsTextAlignment
        self.artistLabel.textAlignment = textAlignment
        self.trackTitleLabel.textAlignment = textAlignment
        
        //Playback buttons
        self.buttonsTopConstraint.constant = state.buttonsTop
        self.buttonsTrailingConstraint.constant = state.buttonsTrailing

        //Playback button spacing
        let buttonsWidth = state.buttonsWidth
        let internalSpacing = (buttonsWidth - (3 * 40.0)) / 2
        
        self.buttonsSpacingConstraint1.constant = internalSpacing
        self.buttonsSpacingConstraint2.constant = internalSpacing
        self.buttonsWidthConstraint.constant = buttonsWidth
        
        //Close button
        self.closeButtonTopConstraint.constant = state.closeButtonTop
        
        //Volume view
        self.volumeTopConstraint.constant = state.volumeTop

        if animated {
            //Animate
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.25, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            })
            return
        }
        //Layout without animating.
        self.layoutIfNeeded()
    }
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        self.updateConstraints(withState: .closed, animated: true)
    }
    
    @IBAction func play(_ sender: Any) {
        let playbackState = MPMusicPlayerController.systemMusicPlayer.playbackState
        if playbackState == .playing {
            MPMusicPlayerController.systemMusicPlayer.pause()
        }
        else {
            MPMusicPlayerController.systemMusicPlayer.play()
        }
        
        self.update(withPlaybackState: playbackState)
    }
    
    @IBAction func next(_ sender: Any) {
        MPMusicPlayerController.systemMusicPlayer.skipToNextItem()
    }
    
    @IBAction func previous(_ sender: Any) {
        MPMusicPlayerController.systemMusicPlayer.skipToPreviousItem()
    }
}

//MARK : - Mini Player State
extension MiniPlayer {
    /// `MiniPlayer.State`: Defines the current visible state of the mini player.
    enum State {
        ///The mini player is open and is the main view on screen.
        case open
        ///The mini player is on screen, but is minimized.
        case closed
        ///The mini player is not on screen.
        case disabled
        
        //MARK: - Mini Player State Positioning and Sizing
        
        ///The size of the mini player for the given state.
        var size: CGSize {
            guard let keyWindow = UIWindow.key else { return CGSize.zero }
            let readableContentFrame = keyWindow.readableContentGuide.layoutFrame
            switch self {
            case .disabled, .closed :
                return CGSize(width: readableContentFrame.width - 16, height: 75.0)
            case .open :
                let width = (readableContentFrame.width - 16)
                let height = width + 199.0
                return CGSize(width: width, height: height)
            }
        }

        ///The position to place the mini player at for the given state.
        func origin(withBottomPadding bottomPadding: CGFloat) -> CGPoint {
            guard let keyWindow = UIWindow.key else { return CGPoint.zero}
            let windowHeight = keyWindow.frame.height
            let stateSize = self.size
            let x = (keyWindow.frame.width / 2) - (stateSize.width / 2)
            
            var y: CGFloat
            switch self {
            case .closed :
                y = windowHeight - stateSize.height - 8.0 - bottomPadding
            case .disabled :
                y = windowHeight + stateSize.height
            case .open :
                y = (windowHeight / 2) - (stateSize.height / 2)
            }
            
            return CGPoint(x: x, y: y)
        }
        
        ///The width of the mini player where views can safely be placed.
        var usableWidth: CGFloat {
            return self.size.width - 32.0
        }
        
        //MARK: - Mini Player Constraint Constants
        
        ///The width value of the artwork image view in the mini player.
        var artworkWidth: CGFloat {
            switch self {
            case .open :
                return self.usableWidth
            default :
                let height = self.size.height
                return height - 24.0
            }
        }
        
        ///The top constraint valuhe of the artwork image view in the mini player.
        var artworkTop: CGFloat {
            switch self {
            case .open :
                return 20.0
            default :
                return 12.0
            }
        }
        
        ///The leading constraint valuhe of the artwork image view in the mini player.
        var artworkLeading: CGFloat {
            switch self {
            case .open :
                return 16.0
            default :
                return 12.0
            }
        }
        
        ///The top constraint value for the title and artist labels in the mini player.
        var labelsTop: CGFloat {
            switch self {
            case .open :
                return self.artworkTop + self.artworkWidth + 12.0
            default :
                return 16.0
            }
        }
        
        ///The width constraint value for the title and artist labels in the mini player.
        var labelsWidth: CGFloat {
            switch self {
            case .open :
                return self.usableWidth
            default :
                return self.usableWidth - self.artworkWidth - self.buttonsWidth - 20.0
            }
        }
        
        ///The leading constraint value for the title and artist labels in the mini player.
        var labelsLeading: CGFloat {
            switch self {
            case .open :
                return 16.0
            default :
                return 30.0 + self.artworkWidth
            }
        }
        
        ///The text alignment for the labels in the mini player.
        var labelsTextAlignment: NSTextAlignment {
            switch self {
            case .open :
                return .center
            default :
                return .natural
            }
        }
        
        ///The top constraint value for the playback buttons in the mini player.
        var buttonsTop: CGFloat {
            switch self {
            case .open :
                return self.labelsTop + 47.0
            default :
                return 12.0
            }
        }
        
        ///The width constraint value for the playback buttons in the mini player.
        var buttonsWidth: CGFloat {
            switch self {
            case .open :
                return self.usableWidth / 2
            default :
                return 130.0
            }
        }
        
        ///The trailing constraint value for the playback buttons in the mini player.
        var buttonsTrailing: CGFloat {
            switch self {
            case .open :
                return (self.size.width / 2) - (self.buttonsWidth / 2)
            default :
                return 12.0
            }
        }
        
        ///The top constraint of the volume view in the mini player.
        var volumeTop: CGFloat {
            switch self {
            case .open :
                return self.buttonsTop + 53.0
            default :
                return self.size.height + 25.0
            }
        }
        
        ///The top constraint of the close button in the mini player.
        var closeButtonTop: CGFloat {
            switch self {
            case .open :
                return 0
            default :
                return -20.0
            }
        }
        
    }
}
