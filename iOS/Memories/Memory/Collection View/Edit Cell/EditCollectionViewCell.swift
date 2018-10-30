//
//  EditCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/10/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class EditCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.imageView.layer.cornerRadius = 10
        self.imageView.backgroundColor = .theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.15) {
            self.imageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.alpha = 0.8
            self.titleLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.15) {
            self.imageView.transform = .identity
            self.alpha = 1
            self.titleLabel.transform = .identity
        }
    }

}
