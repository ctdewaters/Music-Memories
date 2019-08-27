//
//  EditMemoryTrackTableViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/27/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

class EditMemoryTrackTableViewCell: TrackTableViewCell {
    
    //MARK: - Properties
    var deletionCallback: (()->Void)?
        
    //MARK: - Setup
    func setup(withMediaItem mediaItem: MPMediaItem) {
        self.displaySetting = .deletion
        self.track = mediaItem
        
        DispatchQueue.global(qos: .userInteractive).async {
            let artwork = mediaItem.artwork?.image(at: CGSize.square(withSideLength: 150)) ?? #imageLiteral(resourceName: "logo500")
            
            DispatchQueue.main.async {
                self.artwork.image = artwork
            }
        }
        
        self.titleLabel.text = self.track?.title ?? ""
        
        //Set the subtitle label's text.
        let artist = self.track?.artist ?? ""
        let album = self.track?.albumTitle ?? ""
        self.subtitleLabel.text = "\(artist) • \(album)"
    }
    
    //MARK: - IBActions
    @IBAction func deleteAction(_ sender: Any) {
        self.deletionCallback?()
    }
}
