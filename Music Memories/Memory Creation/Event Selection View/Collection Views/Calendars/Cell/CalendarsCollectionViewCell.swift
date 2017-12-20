//
//  CalendarsCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class CalendarsCollectionViewCell: UICollectionViewCell {
    
    static let font = UIFont.systemFont(ofSize: 18, weight: .medium)
    
    //MARK: - IBOutlets
    
    ///Displays the name of the calendar.
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    //MARK: - Setup
    func set(withCalendar calendar: EKCalendar) {
        //Background color setup.
        self.backgroundColor = Settings.shared.textColor
        
        //Set corner radius.
        self.layer.cornerRadius = 12
        
        //Title label setup.
        self.titleLabel.text = calendar.title
        self.titleLabel.font = CalendarsCollectionViewCell.font
        self.titleLabel.textColor = Settings.shared.darkMode ? .black : .white

    }

}
