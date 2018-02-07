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
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var separator: UIView!
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.removeHighlight()
    }
    
    ///Highlights the cell.
    func highlight() {
        let contrastColor: UIColor = Settings.shared.darkMode ? .black : .white
        
        self.separator.backgroundColor = .clear
        self.icon.tintColor = Settings.shared.textColor
        self.icon.backgroundColor = contrastColor
        
        self.backgroundColor = Settings.shared.textColor
        
        self.titleLabel.textColor = contrastColor
        self.subtitleLabel.textColor = contrastColor
    }
    
    //Returns cell to idle state.
    func removeHighlight() {
        self.separator.backgroundColor = Settings.shared.textColor
        
        self.icon.layer.cornerRadius = 30
        self.icon.tintColor = Settings.shared.darkMode ? .black : .white
        
        self.icon.backgroundColor = Settings.shared.textColor
        
        self.titleLabel.textColor = Settings.shared.textColor
        self.subtitleLabel.textColor = Settings.shared.accessoryTextColor
        
        self.backgroundColor = .clear
    }
}
