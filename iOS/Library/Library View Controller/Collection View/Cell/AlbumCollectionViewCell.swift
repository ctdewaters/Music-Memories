//
//  AlbumCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/10/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import LibraryKit
import MediaPlayer
import MemoriesKit

class AlbumCollectionViewCell: UICollectionViewCell {

    //MARK: - IBOutlets.
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?
    
    //MARK: - UICollectionViewCell overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 7
        
        self.titleLabel.textColor = Settings.shared.textColor
        self.artistLabel.textColor = Settings.shared.textColor
        self.playButton.layer.cornerRadius = 37 / 2
        self.playButton.backgroundColor = Settings.shared.darkMode ? UIColor.black.withAlphaComponent(0.75) : UIColor.white.withAlphaComponent(0.75)
        self.playButton.tintColor = Settings.shared.darkMode ? .white : .theme
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSettings), name: Settings.didUpdateNotification, object: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.albumImageView.image = nil
    }
    
    
    //MARK: - Setup.
    ///Sets up this cell with an album.
    public func setup(withAlbum album: MPMediaItemCollection, andAlbumArtworkSize artworkSize: CGSize) {
        self.album = album
        
        //Set label text values.
        var title = album.representativeItem?.albumTitle ?? album.representativeItem?.title ?? ""
        if album.items.count == 1 {
            title = album.representativeItem?.title ?? album.representativeItem?.albumTitle ?? ""
        }
        self.titleLabel.text = title
        self.artistLabel.text = album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let artwork = album.representativeItem?.artwork?.image(at: artworkSize)
            DispatchQueue.main.async {
                self.albumImageView.image = artwork
                self.albumImageView.layer.cornerRadius = 7
            }
        }
    }
    
    //MARK: - Settings updating.
    @objc private func updateSettings() {
        self.titleLabel.textColor = Settings.shared.textColor
        self.artistLabel.textColor = Settings.shared.textColor
        self.playButton.backgroundColor = Settings.shared.darkMode ? UIColor.black.withAlphaComponent(0.75) : UIColor.white.withAlphaComponent(0.75)
        self.playButton.tintColor = Settings.shared.darkMode ? .white : .theme
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            self.backgroundColor = Settings.shared.darkMode ? UIColor.white.withAlphaComponent(0.15) : UIColor.black.withAlphaComponent(0.15)
            self.albumImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.albumImageView.alpha = 0.85
        }, completion: nil)
    }
    
    func unhighlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.backgroundColor = .clear
            self.albumImageView.transform = .identity
            self.albumImageView.alpha = 1
        }, completion: nil)
    }
    
    //MARK: - IBActions.
    @IBAction func play(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let items = self.album?.items {
                MKMusicPlaybackHandler.play(items: items)
            }
        }
    }
}
