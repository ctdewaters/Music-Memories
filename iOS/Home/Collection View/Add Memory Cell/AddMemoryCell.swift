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
            self.alpha = 0.75
        }
    }
    
    func removeHighlight() {
        //Animate to new transforms.
        UIView.animate(withDuration: 0.15) {
            self.transform = .identity
            self.icon.transform = .identity
            self.label.transform = .identity
            self.alpha = 1
        }
    }
}
