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
    
    func set(withMemoryItem item: MKMemoryItem) {
        if let mediaItem = item.mpMediaItem {
            self.itemTitleLabel.text = mediaItem.title ?? ""
            self.itemInfoLabel.text = "\(mediaItem.albumArtist ?? "") - \(mediaItem.albumTitle ?? "")"
            
            self.itemTitleLabel.textColor = Settings.shared.textColor
            self.itemInfoLabel.textColor = Settings.shared.accessoryTextColor
            
            let artwork = mediaItem.artwork?.image(at: CGSize(width: 500, height: 500))
            self.artworkImageView.layer.cornerRadius = 5
            self.artworkImageView.contentMode = .scaleAspectFill
            self.artworkImageView.image = artwork ?? UIImage()
            self.artworkImageView.backgroundColor = themeColor
            
        }
    }
}
