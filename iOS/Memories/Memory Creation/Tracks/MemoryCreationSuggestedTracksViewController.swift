//
//  MemoryCreationTrackSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/18/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

/// `MemoryCreationTrackSelectionViewController`: Allows user to select tracks to add to a memory.
class MemoryCreationSuggestedTracksViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: MemoryCreationTrackSelectionCollectionView!
    @IBOutlet weak var noSongsLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        //Next button setup.
        self.nextButton.frame.size = CGSize.square(withSideLength: 30)
        self.nextButton.cornerRadius = 15
        
        //Set allows addition to false (so the user cannot add tracks to the suggestions).
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.cellSelectionStyle = .unselect
        
        //Load the suggestions.
        self.loadSuggestedTracks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Delete all tracks in the shared memory creation data object.
        MemoryCreationData.shared.mediaItems?.removeAll()
    }
    
    //MARK: Loading Tracks
    ///Loads the suggested tracks, using the date range given by the user earlier.
    func loadSuggestedTracks() {
        guard var startDate = MemoryCreationData.shared.startDate, let endDate = MemoryCreationData.shared.endDate else {
            return
        }
        
        //Increase range before the selected time period.
        startDate = startDate.addingTimeInterval(-45*24*60*60)
        
        var tracks = MPMediaQuery.retrieveItemsAdded(betweenDates: startDate, and: endDate)
        
        //Filter only tracks with greater than 10 plays only if we have more than 35 track suggestions.
        if tracks.count > 35 {
            let filteredTracks = tracks.filter { return $0.playCount > 10 }
            if filteredTracks.count > 7 {
                tracks = filteredTracks
            }
        }
        
        //Add tracks released during the dates.
        var releaseDateTracks = MPMediaQuery.retrieveItemsReleased(betweenDates: startDate, and: endDate)
        
        //Filter only tracks with greater than 10 plays only if we have more than 5 track suggestions.
        if releaseDateTracks.count > 5 {
            let filteredReleaseDateTracks = tracks.filter { return $0.playCount > 10 }
            if filteredReleaseDateTracks.count > 7 {
                releaseDateTracks = filteredReleaseDateTracks
            }
        }
        
        //Add the release date tracks.
        
        for releaseDateTrack in releaseDateTracks {
            if !tracks.contains(releaseDateTrack) {
                tracks.append(releaseDateTrack)
            }
        }
        
        //Sort the tracks array by play count.
        tracks = tracks.sorted {
            $0.playCount > $1.playCount
        }
        
        //Cap at 35 tracks.
        while tracks.count > 35 {
            tracks.remove(at: 35)
        }
        
        if tracks.count == 0 {
            //Show the noSongsLabel.
            self.noSongsLabel.textColor = .label
            self.noSongsLabel.isHidden = false
        }
        else {
            self.noSongsLabel.isHidden = true
        }
        
        self.collectionView.items = tracks
        
        //Start with all tracks selected.
        for track in self.collectionView.items {
            self.collectionView.selectedItems.append(track)
        }
        
        self.collectionView.reloadData()
    }
    
    //MARK: IBActions
    @IBAction func next(_ sender: Any) {
        //Add the selected items to the shared memory creation data object.
        MemoryCreationData.shared.mediaItems = self.collectionView.selectedItems
    }
    
}
