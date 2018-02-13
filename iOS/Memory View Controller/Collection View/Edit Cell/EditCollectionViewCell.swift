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
        self.imageView.backgroundColor = .themeColor
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.alpha = 0.8
            self.titleLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }, completion: nil)
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.imageView.transform = .identity
            self.alpha = 1
            self.titleLabel.transform = .identity
        }, completion: nil)
    }

}
