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
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    //MARK: - Properties.
    ///The color of the arrows and text.
    var contentTintColor: UIColor {
        set {
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
        
        self.settingsUpdated()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsUpdated), name: Settings.didUpdateNotification, object: nil)
    }
    
    //MARK: - Settings updated.
    @objc private func settingsUpdated() {
        self.contentTintColor = UIColor.navigationForeground
    }
}
