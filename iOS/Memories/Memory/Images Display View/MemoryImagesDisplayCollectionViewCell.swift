//
//  MemoryImagesDisplayCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/5/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryImagesDisplayCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Properties
    ///The image view, which will display the associated image.
    var imageView: UIImageView?
    
    ///The image to display.
    var image: UIImage?
    
    //MARK: - Overrides
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Set up the image view.
        self.imageView = UIImageView(frame: .zero)
        self.contentView.addSubview(self.imageView!)
        self.imageView?.bindFrameToSuperviewBounds()
        self.imageView?.clipsToBounds = true
        self.imageView?.contentMode = .scaleAspectFill
        self.imageView?.image = self.image
        self.imageView?.backgroundColor = UIColor.secondarySystemFill
    }
    
    func set(withImage image: UIImage) {
        self.image = image
        self.imageView?.image = self.image
    }
}
