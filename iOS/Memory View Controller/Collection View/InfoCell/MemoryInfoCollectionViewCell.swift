//
//  MemoryInfoCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/16/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryInfoCollectionViewCell: UICollectionViewCell {

    //MARK: - IBOutlets
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var separator: UIView!
    
    //MARK: - Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //Text color.
        self.dateLabel.textColor = .themeColor
        self.descriptionView.textColor = Settings.shared.accessoryTextColor.withAlphaComponent(0.75)
        self.separator.backgroundColor = Settings.shared.accessoryTextColor
    }
    
    //MARK: - Setup
    func setup(withMemory memory: MKMemory) {
        if let desc = memory.desc {
            self.descriptionView.text = desc
        }
        else {
            self.descriptionView.removeFromSuperview()
        }
        //Date setup.
        if let startDate = memory.startDate {
            self.dateLabel.isHidden = false
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.dateLabel.text = "\(startDate.medString) • \(endDate.medString)"
                }
                else {
                    self.dateLabel.text = startDate.longString
                }
            }
            else {
                self.dateLabel.text = startDate.longString
            }
        }
        else {
            self.dateLabel.isHidden = true
        }
    }
}
