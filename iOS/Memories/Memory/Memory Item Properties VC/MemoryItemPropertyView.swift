//
//  MemoryItemPropertyView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/21/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer

///`MemoryItemPropertyView`: provides UI for a Memory Item property.
class MemoryItemPropertyView: UIView {
    //MARK: - IBOutlets.
    @IBOutlet weak var captionLabel: UILabel?
    @IBOutlet weak var propertyBackgroundView: UIView?
    @IBOutlet weak var propertyLabel: UILabel?
    
    //MARK: - `MemoryItemPropertyView.PropertyType`
    ///`MemoryItemPropertyView.PropertyType`: defines the property to display.
    enum PropertyType {
        case playCount, dateAdded, lastPlayed
        
        var displayTitle: String {
            switch self {
            case .dateAdded :
                return "Date Added"
            case .lastPlayed :
                return "Last Played"
            case.playCount :
                return "Play Count"
            }
        }
    }
    
    //MARK: - UIView overrides.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //View setup.
        self.propertyBackgroundView?.layer.cornerRadius = (self.propertyBackgroundView?.frame.width ?? 0) / 2
        self.propertyBackgroundView?.backgroundColor = .theme
        self.propertyLabel?.textColor = .white
        self.captionLabel?.textColor = Settings.shared.textColor
        self.backgroundColor = .clear
    }
    
    //MARK: - Setup.
    ///Sets up the view with a given property type and media item.
    func setup(withMediaItem item: MPMediaItem?, andPropertyType propertyType: PropertyType) {
        //Unwrap memory item.
        guard let mediaItem = item else {
            return
        }
        
        //Set the caption label's text to the property type's display title property.
        self.captionLabel?.text = propertyType.displayTitle
        
        //Setup property view.
        switch propertyType {
        case .dateAdded :
            self.propertyLabel?.text = self.string(fromDate: mediaItem.dateAdded)
            break
        case .lastPlayed :
            self.propertyLabel?.text = self.string(fromDate: mediaItem.lastPlayedDate)
            break
        case.playCount :
            self.propertyLabel?.text = "\(mediaItem.playCount)"
            break
        }
    }
    
    //MARK: - `DateFormatter`
    func string(fromDate date: Date?) -> String {
        guard let date = date else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(for: date) ?? ""
    }
}
