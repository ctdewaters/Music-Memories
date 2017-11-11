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
        self.imageView.layer.cornerRadius = 7
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
