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

class AlbumCollectionViewCell: UICollectionViewCell {

    //MARK: - IBOutlets.
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    
    //MARK: - UICollectionViewCell overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.titleLabel.textColor = Settings.shared.textColor
        self.artistLabel.textColor = Settings.shared.textColor
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSettings), name: Settings.didUpdateNotification, object: nil)
    }
    
    
    //MARK: - Setup.
    ///Sets up this cell with an album.
    public func setup(withAlbum album: MPMediaItemCollection) {
        self.titleLabel.text = album.representativeItem?.albumTitle ?? album.representativeItem?.title ?? ""
        self.artistLabel.text = album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? ""
        
        DispatchQueue.global(qos: .userInitiated).async {
            let artwork = album.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: 150))
            DispatchQueue.main.async {
                self.albumImageView.image = artwork
                self.albumImageView.layer.cornerRadius = 7
                self.albumImageView.layer.borderWidth = 0.5
                self.albumImageView.layer.borderColor = UIColor.theme.cgColor
            }
        }
    }
    
    //MARK: - Settings updating.
    @objc private func updateSettings() {
        self.titleLabel.textColor = Settings.shared.textColor
        self.artistLabel.textColor = Settings.shared.textColor
    }
}
