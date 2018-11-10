//
//  LibraryTableSectionHeaderView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/31/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

///`LibraryTableSectionHeaderView`: Displays the year of the albums represented in the section.
class LibrarySectionHeaderView: UICollectionReusableView {
    //MARK: - IBOutlets.
//    @IBOutlet weak var button: UIButton!
//    @IBOutlet weak var arrow1: UIImageView!
//    @IBOutlet weak var arrow2: UIImageView!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    //MARK: - Properties.
    ///The color of the arrows and text.
    var contentTintColor: UIColor {
        set {
//            self.arrow1.tintColor = newValue
//            self.arrow2.tintColor = newValue
            self.yearLabel.textColor = newValue
            self.infoLabel.textColor = newValue
        }
        get {
            return self.yearLabel.textColor
        }
    }
    
    var isOpen = true
    
    
    //MARK: - UIView overrides.
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
//        self.button.addTarget(self, action: #selector(self.highlight), for: .touchDown)
//        self.button.addTarget(self, action: #selector(self.highlight), for: .touchDragEnter)
//        self.button.addTarget(self, action: #selector(self.unhighlight), for: .touchDragExit)
        
        self.contentTintColor = .theme
    }
    
    //MARK: - IBActions.
    @IBAction func buttonPressed(_ sender: Any) {
        //Invert isOpen.
        self.isOpen = !self.isOpen
        
        //Unhighlight
        self.unhighlight()
        
        //Animate arrows.
//        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
//            self.arrow1.transform = CGAffineTransform(rotationAngle: self.isOpen ? 0 : .pi)
//            self.arrow2.transform = CGAffineTransform(rotationAngle: self.isOpen ? 0 : .pi)
//        }, completion: nil)
    }
    
    //MARK: - Highlighting.
    @objc func highlight() {
//        self.arrow1.alpha = 0.5
//        self.arrow2.alpha = 0.5
        self.yearLabel.alpha = 0.5
    }
    
    @objc func unhighlight() {
//        self.arrow1.alpha = 1
//        self.arrow2.alpha = 1
        self.yearLabel.alpha = 1
    }
}
