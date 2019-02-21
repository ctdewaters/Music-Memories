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

class TrackTableViewCell: UITableViewCell {

    //MARK: - IBOutlets.
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var trackNumberLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    //MARK: - Properties.
    ///The track represented by this cell.
    var track: MPMediaItem?
    
    ///The music player indicator.
    var musicIndicator: ESTMusicIndicatorView?
    
    //MARK: - Overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        

        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsUpdated), name: Settings.didUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemChanged), name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemStateChanged), name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        
        self.settingsUpdated()
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
    func setup(withItem item: MPMediaItem) {
        self.track = item
        self.titleLabel.text = item.title ?? ""
        self.trackNumberLabel.text = "\(item.albumTrackNumber)"
        self.durationLabel.text = item.playbackDuration.stringValue
    }
    
    //MARK: - Settings updated.
    @objc func settingsUpdated() {
        self.titleLabel.textColor = Settings.shared.textColor
        self.trackNumberLabel.textColor = Settings.shared.textColor
        self.durationLabel.textColor = Settings.shared.textColor
        self.musicIndicator?.tintColor = Settings.shared.darkMode ? .white : .theme
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
        if self.musicIndicator == nil {
            self.musicIndicator = ESTMusicIndicatorView(frame: self.trackNumberLabel.frame)
            self.musicIndicator?.tintColor = Settings.shared.darkMode ? .white : .theme
            self.contentView.addSubview(musicIndicator!)
        }
        
        UIView.animate(withDuration: 0.2) {
            if on {
                //Toggle on.
                self.trackNumberLabel.alpha = 0
                self.musicIndicator?.alpha = 1
                self.musicIndicator?.state = .playing
                return
            }
            //Toggle off.
            self.trackNumberLabel.alpha = 1
            self.musicIndicator?.alpha = 0
        }
    }
}

extension TimeInterval {
    var stringValue: String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        return String(format: "%d:%02d", minutes, seconds)
    }
}
