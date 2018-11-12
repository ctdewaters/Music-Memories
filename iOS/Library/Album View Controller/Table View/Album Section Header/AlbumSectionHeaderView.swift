//
//  AlbumSectionHeaderView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

class AlbumSectionHeaderView: UIView {

    //MARK: - IBOutlets.
    @IBOutlet weak var blurBackground: UIVisualEffectView!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var addedDateLabel: UILabel!
    @IBOutlet weak var playCountLabel: UILabel!
    
    //MARK: - Overrides.
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsUpdated), name: Settings.didUpdateNotification, object: nil)
        
        self.playCountLabel.backgroundColor = .theme
        self.playCountLabel.layer.cornerRadius = self.playCountLabel.frame.height / 2
        
        self.settingsUpdated()
    }
    
    //MARK: - Settings updated.
    @objc func settingsUpdated() {
        self.blurBackground.effect = UIBlurEffect(style: Settings.shared.darkMode ? .dark : .extraLight)
        self.albumLabel.textColor = Settings.shared.darkMode ? .white : .theme
        self.genreLabel.textColor = Settings.shared.textColor
        self.addedDateLabel.textColor = Settings.shared.textColor
        self.releaseDateLabel.textColor = Settings.shared.textColor
    }
    
    //MARK: - Setup.
    func setup(withAlbum album: MPMediaItemCollection) {
        self.albumLabel.text = album.representativeItem?.albumTitle ?? ""
        self.genreLabel.text = album.representativeItem?.genre ?? ""
        self.releaseDateLabel.text = "Released On \((album.representativeItem?.releaseDate ?? Date()).medString)"
        self.addedDateLabel.text = "Added On \((album.representativeItem?.dateAdded ?? Date()).medString)"
        
        //Calculate total play count of all songs in background thread.
        DispatchQueue.global(qos: .userInitiated).async {
            var count = 0
            for item in album.items {
                count += item.playCount
            }
            DispatchQueue.main.async {
                self.playCountLabel.text = "\(count)"
            }
        }
    }
}
