//
//  CalendarsCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit
import MarqueeLabel

class CalendarsCollectionViewCell: UICollectionViewCell {
    
    static let font = UIFont.systemFont(ofSize: 18, weight: .medium)
    
    //MARK: - IBOutlets
    
    ///Displays the name of the calendar.
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sourceLabel: MarqueeLabel!
    
    var calendar: EKCalendar?
    
    var userSelected = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    //MARK: - Setup
    func set(withCalendar calendar: EKCalendar) {
        //Set the calendar
        self.calendar = calendar
        
        //Selection UI setup.
        self.toggleSelect()
        
        //Set corner radius.
        self.layer.cornerRadius = 12
        
        //Title label setup.
        self.titleLabel.text = calendar.title
        self.titleLabel.font = CalendarsCollectionViewCell.font
        
        //Source label setup.
        self.sourceLabel.text = "In \(calendar.source.title)    "
        self.sourceLabel.fadeLength = 5
        self.sourceLabel.type = .continuous

    }
    
    func toggleSelect() {
        self.userSelected = self.userSelected ? false : true
        let calendarColor = UIColor(cgColor: self.calendar!.cgColor)
        self.backgroundColor = self.userSelected ? calendarColor : Settings.shared.textColor
        self.titleLabel.textColor = self.userSelected ? Settings.shared.textColor : calendarColor
        self.sourceLabel.textColor = self.titleLabel.textColor
    }
    
    func highlight(on: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = on ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            self.alpha = on ? 0.75 : 1
        }, completion: nil)
    }

}
