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
        
        self.collectionView.allowsAddition = false
        
        self.loadSuggestedTracks()
    }
    
    //Load the suggested tracks, using the date range given by the user earlier.
    func loadSuggestedTracks() {
        guard let startDate = memoryComposeVC?.memory?.startDate, let endDate = memoryComposeVC?.memory?.endDate else {
            return
        }
        let tracks = MPMediaQuery.retrieveItemsAdded(betweenDates: startDate, and: endDate).sorted {
            $0.dateAdded < $1.dateAdded
        }
        self.collectionView.items = tracks
        
        self.collectionView.reloadData()
    }
}
