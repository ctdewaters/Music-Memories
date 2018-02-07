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
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.cellSelectionStyle = .unselect
        
        //Load the suggestions.
        self.loadSuggestedTracks()
    }
    
    //Load the suggested tracks, using the date range given by the user earlier.
    func loadSuggestedTracks() {
        guard let startDate = memoryComposeVC?.memory?.startDate, let endDate = memoryComposeVC?.memory?.endDate else {
            return
        }
        
        var tracks = MPMediaQuery.retrieveItemsAdded(betweenDates: startDate, and: endDate).sorted {
            return $0.dateAdded < $1.dateAdded
        }
        
        //Filter only tracks with greater than 15 plays only if we have more than 25 track suggestions.
        if tracks.count > 25 {
            tracks = (tracks.filter { return $0.playCount > 15 }.count > 7 ? tracks.filter { return $0.playCount > 15 } : tracks).sorted {
                return $0.playCount > $1.playCount
            }
        }
        
        //Cap at 25 tracks.
        while tracks.count > 25 {
            tracks.remove(at: 25)
        }
        
        self.collectionView.items = tracks
        //Start with all tracks selected.
        for track in self.collectionView.items {
            self.collectionView.selectedItems.append(track)
        }
        
        self.collectionView.reloadData()
    }
    
    //MARK: - IBActions
    @IBAction func back(_ sender: Any) {
        memoryComposeVC?.dismissView()
    }
    
    @IBAction func next(_ sender: Any) {
        
        //Add all the selected songs to the memory as MKMemoryItems.
        for item in self.collectionView.selectedItems {
            let mkItem = item.mkMemoryItem
            mkItem.memory = memoryComposeVC?.memory
        }
        
        memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Add any more tracks you wish to associate with this memory.")
        
    }
}
