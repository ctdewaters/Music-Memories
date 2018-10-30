//
//  MemoryComposeTypeCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MarqueeLabel

class MemoryComposeTypeCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.removeHighlight()
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 25
        
        self.backgroundColor = .darkGray
    }
    
    ///Highlights the cell.
    func highlight() {
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.alpha = 0.85
        }
    }
    
    //Returns cell to idle state.
    func removeHighlight() {
        let contrastColor: UIColor = .white
        self.icon.tintColor = contrastColor
        self.titleLabel.textColor = contrastColor
        
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
            self.alpha = 1
        }

    }
}
