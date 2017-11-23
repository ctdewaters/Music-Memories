//
//  ImageSelectionCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/22/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class ImageSelectionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var deleteCallback: (()->Void)?
    
    var index = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        self.deleteButton.layer.cornerRadius = 22 / 2
        self.layer.cornerRadius = 11
        
        self.deleteButton.addTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
    }

    
    @objc func deleteButtonPressed() {
        self.deleteButton.removeTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
        self.deleteCallback?()
    }
}
