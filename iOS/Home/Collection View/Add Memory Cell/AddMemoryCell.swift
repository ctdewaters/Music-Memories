//
//  AddMemoryCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class AddMemoryCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var labelCenterConstraint: NSLayoutConstraint!
    
    var cornerRadius: CGFloat = 10
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        //Set corner radius
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
        self.backgroundColor = .themeColor
        self.icon.tintColor = .white
        self.label.textColor = .white
    }
    
    func highlight() {
        //Animate to new transforms.
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 0.87, y: 0.87)
            self.icon.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.75)
        }
    }
    
    func removeHighlight() {
        //Animate to new transforms.
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
            self.icon.transform = .identity
            self.label.transform = .identity
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(1)
        }
    }
}
