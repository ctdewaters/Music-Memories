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
    
    ///The shadow view.
    var shadowView: UIView!
    
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
        self.imageView?.layer.cornerRadius = 10
        self.imageView?.backgroundColor = UIColor.secondarySystemFill
        
        self.shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.imageView?.frame.width ?? 0, height: self.imageView?.frame.height ?? 0))
        self.contentView.addSubview(self.shadowView)
        self.shadowView.bindFrameToSuperviewBounds()
        self.shadowView.backgroundColor = .white
        self.contentView.bringSubviewToFront(self.imageView!)
        self.shadowView.shadowColor = .black
        self.shadowView.shadowOpacity = 1
        self.shadowView.shadowOffset = CGPoint(x: 0, y: 4)
        self.shadowView.shadowRadius = 7
        self.shadowView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
    }
    
    func set(withImage image: UIImage) {
        self.image = image
        self.imageView?.image = self.image
    }
}
