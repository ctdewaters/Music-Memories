//
//  TrackTableViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer
import LibraryKit
import MemoriesKit
import ESTMusicIndicator

/// `TrackTableViewCell`: Displays a `MPMediaItem` object in a `MediaCollectionViewController`.
class TrackTableViewCell: UITableViewCell {

    //MARK: - IBOutlets.
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var trackNumberLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var musicIndicatorHoldingView: UIView!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelCenterYConstraint: NSLayoutConstraint!
    
    //MARK: - Properties.
    ///The track represented by this cell.
    var track: MPMediaItem?
    
    ///The music player indicator.
    var musicIndicator: ESTMusicIndicatorView?
    
    /// `TrackTableViewCell.DisplaySetting`: Provides two cases for views housed left of the title label: artwork and track number.
    enum DisplaySetting {
        case artwork, trackNumber, deletion
    }
    var displaySetting: DisplaySetting = .trackNumber
    
    //MARK: - Overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsUpdated), name: Settings.didUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemChanged), name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemStateChanged), name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.nowPlayingItemChanged()
    }
    
    //MARK: - Setup.
    /// Sets the cell with an `MPMediaItem` object.
    /// - Parameter item: The media item to display.
    /// - Parameter displaySetting: A display setting, either showing the album art or track number.
    /// - Parameter showSubtitle: If true, a subtitle label will be shown containing the artist and album name of the media item.
    func setup(withItem item: MPMediaItem, andDisplaySetting displaySetting: TrackTableViewCell.DisplaySetting = .trackNumber, showSubtitle: Bool = false) {
        self.displaySetting = displaySetting
        
        self.track = item
        self.titleLabel.text = item.title ?? ""
        self.durationLabel.text = item.playbackDuration.stringValue

        if displaySetting == .trackNumber {
            self.artwork.isHidden = true
            self.trackNumberLabel.isHidden = false
            self.trackNumberLabel.text = "\(item.albumTrackNumber)"
        }
        else if displaySetting == .artwork {
            self.trackNumberLabel.isHidden = true
            self.artwork.isHidden = false
            
            DispatchQueue.global(qos: .userInteractive).async {
                let artworkImage = item.artwork?.image(at: CGSize.square(withSideLength: 50.0)) ?? #imageLiteral(resourceName: "logo500").scale(toSize: CGSize.square(withSideLength: 200.0))
                DispatchQueue.main.async {
                    self.artwork.image = artworkImage
                }
            }
            
            self.titleLabelLeadingConstraint.constant = 34.0
            self.layoutIfNeeded()
        }
        
        if showSubtitle {
            //Show the subtitle label.
            self.subtitleLabel.isHidden = false
            
            //Set the subtitle label's text.
            let artist = self.track?.artist ?? ""
            let album = self.track?.albumTitle ?? ""
            self.subtitleLabel.text = "\(artist) • \(album)"
            
            self.titleLabelCenterYConstraint.constant = -10
            self.layoutIfNeeded()
        }
        else {
            //Hide the subtitle label.
            self.subtitleLabel.isHidden = true
            self.titleLabelCenterYConstraint.constant = 0
            self.layoutIfNeeded()
        }
    }
    
    //MARK: - Settings updated.
    @objc func settingsUpdated() {
        self.titleLabel.textColor = .text
        self.trackNumberLabel.textColor = .secondaryText
        self.durationLabel.textColor = .secondaryText
        self.musicIndicator?.tintColor = .theme
    }
    
    //MARK: - MediaPlayerNotifications.
    @objc private func nowPlayingItemChanged() {
        if let nowPlayingItem = MKMusicPlaybackHandler.nowPlayingItem {
            if nowPlayingItem.persistentID == self.track?.persistentID {
                //Display now playing UI.
                self.toggleNowPlaying(toOn: true)
                return
            }
        }
        //Hide now playing UI.
        self.toggleNowPlaying(toOn: false)
    }
    
    @objc private func nowPlayingItemStateChanged() {
        if let nowPlayingItem = MKMusicPlaybackHandler.nowPlayingItem {
            if nowPlayingItem.persistentID == self.track?.persistentID {
                //Toggle state based on new state of player.
                if MKMusicPlaybackHandler.mediaPlayerController.playbackState == .interrupted || MKMusicPlaybackHandler.mediaPlayerController.playbackState == .paused {
                    self.musicIndicator?.state = .paused
                }
                else if MKMusicPlaybackHandler.mediaPlayerController.playbackState == .playing || MKMusicPlaybackHandler.mediaPlayerController.playbackState == .seekingForward || MKMusicPlaybackHandler.mediaPlayerController.playbackState == .seekingBackward {
                    self.musicIndicator?.state = .playing
                }
                return
            }
        }
        //Hide now playing UI.
        self.toggleNowPlaying(toOn: false)
    }
    
    //MARK: - Now Playing UI control.
    private func toggleNowPlaying(toOn on: Bool) {
        
        //Create the music indicator, if it is nil.
        if self.musicIndicator == nil && self.displaySetting != .deletion {
            self.musicIndicator = ESTMusicIndicatorView(frame: (self.displaySetting == .trackNumber) ? self.trackNumberLabel?.frame ?? .zero : self.artwork.bounds)
            self.musicIndicator?.tintColor = .navigationForeground
            
            if self.displaySetting == .trackNumber {
                self.contentView.addSubview(self.musicIndicator!)
            }
            else {
                self.musicIndicatorHoldingView.addSubview(self.musicIndicator!)
            }
        }
        
        UIView.animate(withDuration: 0.2) {
            if on {
                //Toggle on.
                if self.displaySetting == .trackNumber {
                    self.trackNumberLabel.alpha = 0
                }
                else {
                    self.artwork.alpha = 0.4
                }
                
                self.musicIndicator?.alpha = 1
                self.musicIndicator?.state = .playing
                self.musicIndicator?.tintColor = .theme
                self.titleLabel.textColor = .theme
                self.durationLabel?.textColor = .theme
                return
            }
            //Toggle off.
            self.trackNumberLabel?.alpha = 1
            self.artwork.alpha = 1
            self.musicIndicator?.alpha = 0
            self.titleLabel.textColor = .text
            self.durationLabel?.textColor = .secondaryText
        }
    }
}

extension TimeInterval {
    var stringValue: String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
