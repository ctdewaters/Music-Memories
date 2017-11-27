//
//  MemoryItemCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/6/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer
import MarqueeLabel

class MemoryItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: MarqueeLabel!
    @IBOutlet weak var itemInfoLabel: MarqueeLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    //MARK: - Setup
    func set(withMemoryItem item: MKMemoryItem) {
        if let mediaItem = item.mpMediaItem {
            self.set(withMPMediaItem: mediaItem)
        }
    }
    
    func set(withMPMediaItem mediaItem: MPMediaItem) {
        //Set up the labels.
        self.itemTitleLabel.text = "\(mediaItem.title ?? "")        "
        self.itemInfoLabel.text = "\(mediaItem.albumArtist ?? "") - \(mediaItem.albumTitle ?? "")        "
        self.itemTitleLabel.textColor = Settings.shared.textColor
        self.itemInfoLabel.textColor = Settings.shared.accessoryTextColor
        
        //Label marquee settings
        self.itemTitleLabel.fadeLength = 7
        self.itemInfoLabel.fadeLength = 7
        
        //Setup the artwork
        let artwork = mediaItem.artwork?.image(at: CGSize(width: 500, height: 500))
        self.artworkImageView.layer.cornerRadius = 5
        self.artworkImageView.contentMode = .scaleAspectFill
        self.artworkImageView.image = artwork ?? UIImage()
        self.artworkImageView.backgroundColor = .themeColor
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.artworkImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.itemInfoLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.itemTitleLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        }, completion: nil)
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.artworkImageView.transform = .identity
            self.itemInfoLabel.transform = .identity
            self.itemTitleLabel.transform = .identity
            self.backgroundColor = .clear
        }, completion: nil)
    }

}
