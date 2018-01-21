//
//  EventsCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 1/20/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MarqueeLabel
import EventKit

class EventsCollectionViewCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var calendarTitleLabel: MarqueeLabel!
    @IBOutlet weak var eventDatesLabel: MarqueeLabel!
    @IBOutlet weak var separator: UIView!
    
    //MARK: - Properties
    ///The event this cell displays.
    weak var event: EKEvent?
    
    //MARK: - UIView overrides

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.titleLabel.fadeLength = 10
    }
    
    //MARK: - Setup
    func setup(withEvent event: EKEvent) {
        self.event = event
        
        //Setup UI with event info.
        //Colors
        let tintColor = UIColor(cgColor: event.calendar.cgColor)
        self.set(color: tintColor)
        
        //Set label text values.
        self.titleLabel.text = event.title ?? ""
        self.descriptionLabel.text = event.notes ?? ""
        self.calendarTitleLabel.text = "In \(event.calendar.title)"
        self.eventDatesLabel.text = "\(event.startDate.shortString) - \(event.endDate.shortString)"
        
        self.titleLabel.triggerScrollStart()
    }
    
    private func set(color: UIColor) {
        //Set label text colors.
        for view in self.contentView.subviews {
            if let label = view as? UILabel {
                label.textColor = color
            }
        }
        
        //Separator color
        self.separator.backgroundColor = color
        
        self.backgroundColor = .clear
    }
    
    func highlight() {
        if let event = self.event {
            self.set(color: .white)
            self.separator.backgroundColor = .clear
            self.backgroundColor = UIColor(cgColor: event.calendar.cgColor)
        }
    }
    
    func unhighlight() {
        if let event = self.event {
            self.set(color: UIColor(cgColor: event.calendar.cgColor))
            self.backgroundColor = .clear
        }
    }

}

extension Date {
    var shortString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: self)
    }
}
