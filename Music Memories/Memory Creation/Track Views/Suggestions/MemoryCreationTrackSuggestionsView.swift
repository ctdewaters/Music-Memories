//
//  MemoryCreationTrackSuggestionsView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/9/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

class MemoryCreationTrackSuggestionsView: MemoryCreationView {

    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: MemoryCreationTrackSelectionCollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.textColor
                button.layer.cornerRadius = 10
            }
        }
        self.nextButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        
        //Set allows addition to false (so the user cannot add tracks to the suggestions).
        self.collectionView.selectionStyle = .multiple
        
        //Load the suggestions.
        self.loadSuggestedTracks()
    }
    
    //Load the suggested tracks, using the date range given by the user earlier.
    func loadSuggestedTracks() {
        guard let startDate = memoryComposeVC?.memory?.startDate, let endDate = memoryComposeVC?.memory?.endDate else {
            return
        }
        var tracks = MPMediaQuery.retrieveItemsAdded(betweenDates: startDate, and: endDate).sorted {
            $0.dateAdded < $1.dateAdded
        }
        self.collectionView.items = tracks
        
        //Filter only tracks with greater than 10 plays.
        tracks = tracks.filter {
            $0.playCount > 10
        }
        
        self.collectionView.reloadData()
    }
}
