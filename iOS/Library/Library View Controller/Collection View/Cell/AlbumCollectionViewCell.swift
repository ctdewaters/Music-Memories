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
                
        self.playButton.layer.cornerRadius = 37 / 2
        self.playButton.backgroundColor = .background
        self.playButton.tintColor = .navigationForeground
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSettings), name: Settings.didUpdateNotification, object: nil)
        
        self.albumImageView.tintColor = .theme
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
        
        DispatchQueue.global(qos: .userInteractive).async {
            let artwork = album.representativeItem?.artwork?.image(at: artworkSize)
            DispatchQueue.main.async {
                self.albumImageView.image = artwork ?? UIImage(named: "logo500")
                self.albumImageView.layer.cornerRadius = 5
            }
        }
    }
    
    //MARK: - Settings updating.
    @objc private func updateSettings() {
        self.titleLabel.textColor = .text
        self.artistLabel.textColor = .text
        self.playButton.backgroundColor = UIColor.background.withAlphaComponent(0.75)
        self.playButton.tintColor = .navigationForeground
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn, animations: {
            self.albumImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.titleLabel.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.artistLabel.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.titleLabel.alpha = 0.75
            self.artistLabel.alpha = 0.75
        }, completion: nil)
    }
    
    func unhighlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.albumImageView.transform = .identity
            self.titleLabel.transform = .identity
            self.artistLabel.transform = .identity
            self.titleLabel.alpha = 1
            self.artistLabel.alpha = 1
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
