//
//  TrackTableViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer
import LibraryKit

class TrackTableViewCell: UITableViewCell {

    //MARK: - IBOutlets.
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var trackNumberLabel: UILabel!
    
    //MARK: - Overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsUpdated), name: Settings.didUpdateNotification, object: nil)
        
        self.settingsUpdated()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //MARK: - Setup.
    func setup(withItem item: MPMediaItem) {
        self.titleLabel.text = item.title ?? ""
        self.trackNumberLabel.text = "\(item.albumTrackNumber)"
    }
    
    //MARK: - Settings updated.
    @objc func settingsUpdated() {
        self.titleLabel.textColor = Settings.shared.textColor
        self.trackNumberLabel.textColor = Settings.shared.textColor
    }
}
