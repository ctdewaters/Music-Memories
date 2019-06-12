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
    @IBOutlet weak var calendarColorIndicatorView: UIView!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var calendarTitleLabelTopConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    ///The event this cell displays.
    weak var event: EKEvent?
    
    //MARK: - UIView overrides

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.titleLabel.fadeLength = 10
        self.calendarColorIndicatorView.layer.cornerRadius = 5
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
        
        //Date text.
        self.eventDatesLabel.text = event.startDate.noon == event.endDate.noon ? event.startDate.longString : "\(event.startDate.shortString) - \(event.endDate.shortString)"
        
        //Calendar title label Y placement.
        //Check text in the description label.
        if self.descriptionLabel.text == "" {
            //No text, move the calendar title label up using its top constraint.
            self.calendarTitleLabelTopConstraint.constant = -self.descriptionLabel.frame.height
        }
        else {
            self.calendarTitleLabelTopConstraint.constant = 4
        }
        
        self.titleLabel.triggerScrollStart()
    }
    
    private func set(color: UIColor, changeLabels: Bool = false) {
        //Set label text colors.
        for view in self.contentView.subviews {
            if let label = view as? UILabel {
                if changeLabels || label == self.calendarTitleLabel {
                    label.textColor = color
                }
                else {
                    label.textColor = .label
                }
            }
        }
        
        //Separator color
        self.separator.backgroundColor = .tertiaryLabel
        
        //Calendar color indicator view.
        self.calendarColorIndicatorView.backgroundColor = changeLabels ? .label : color
        
        self.backgroundColor = .clear
    }
    
    func highlight() {
        if let event = self.event {
            self.set(color: .white, changeLabels: true)
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
