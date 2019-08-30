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

/// `MiniPlayer`: A `UIView` that provides access to seeking and playback controls for the global media player.
class MiniPlayer: UIView {

    //MARK: - Properties
    
    ///The state of the mini player.
    var state: MiniPlayer.State = .disabled
    
    ///The padding below the miniplayer in the `closed` state.
    var bottomPadding: CGFloat = 75.0
    
    //MARK: - IBOutlets
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var trackTitleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var playbackButtonsContainerView: UIView!
    
    
    //MARK: - Update Functions
    func update(withState state: MiniPlayer.State, animated: Bool = true) {
        let newSize = state.size
        let newOrigin = state.origin(withBottomPadding: self.bottomPadding)
        let newFrame = CGRect(origin: newOrigin, size: newSize)
        
        if animated {
            //Animate
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.frame = newFrame
            }, completion: nil)
        }
        else {
            //Set new values based on state.
            self.frame = newFrame
        }
        self.state = state
    }
    
    func update(padding: CGFloat) {
        self.bottomPadding = padding
        
        self.update(withState: self.state, animated: self.state != .disabled)
        
        UIWindow.key?.bringSubviewToFront(self)
    }
    
    func update(withPlaybackState playbackState: MPMusicPlaybackState) {
        self.playPauseButton.setImage(playbackState == .playing ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill"), for: .normal)
    }
    
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
    
    //MARK: - IBActions
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
                return CGSize(width: width, height: width * 1.75)
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
    }
    
}
