//
//  ArtworkCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class ArtworkCollectionViewCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var playButton: UIButton!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.playButton.clipsToBounds = true
        self.playButton.layer.cornerRadius = self.playButton.frame.height / 2
        self.collectionView.backgroundColor = .clear
    }
    
    @IBAction func play(_ sender: Any) {
    }
}
