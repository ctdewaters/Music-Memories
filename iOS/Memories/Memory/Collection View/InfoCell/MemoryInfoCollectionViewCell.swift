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
    
    //MARK: - Overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        //Text color.
        self.dateLabel.textColor = .theme
        self.descriptionView.textColor = Settings.shared.accessoryTextColor
    }
    
    //MARK: - Setup
    func setup(withMemory memory: MKMemory) {
        self.descriptionView.attributedPlaceholder = NSAttributedString(string: "Enter description here...", attributes: [NSAttributedString.Key.foregroundColor : Settings.shared.accessoryTextColor.withAlphaComponent(0.75), .font : UIFont.systemFont(ofSize: 14, weight: .semibold)])
        if let desc = memory.desc {
            self.descriptionView.text = desc
        }
        //Date setup.
        if let startDate = memory.startDate {
            self.dateLabel.isHidden = false
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.dateLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
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
            self.dateLabel.text = "No Dates"
            self.dateLabel.textColor = UIColor.theme.withAlphaComponent(0.7)
        }
    }
    
    //MARK: - DateIntervalFormatter.
    ///Creates and interval string using a start and end date.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
}
