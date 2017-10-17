//
//  MKMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData
import MediaPlayer

///Represents a memory playlist.
public class MKMemory: NSManagedObject {
    
    /// The completion handler that is called when an Apple Music Get Recently Played API call completes.
    public typealias UpdateCompletionHandler = (_ success: Bool) -> Void

    ///The name of this memory.
    @NSManaged public var title: String?
    
    ///The items in this memory playlist.
    @NSManaged public var items: Set<MKMemoryItem>?
    
    ///The ID this memory is stored with.
    @NSManaged public var storageID: String!
    
    ///The images associated with this memory.
    @NSManaged public var images: Set<MKImage>?
    
    ///The date this memory began.
    @NSManaged public var startDate: Date?
    
    ///The date this memory ended.
    @NSManaged public var endDate: Date?
    
    //MARK: - MPMediaItems list.
    public var mpMediaItems: Set<MPMediaItem>? {
        guard let items = self.items else {
            return nil
        }
        var returnedItems = Set<MPMediaItem>()
        for item in items {
            if let mediaItem = item.mpMediaItem {
                returnedItems.insert(mediaItem)
            }
        }
        return returnedItems
    }
    
    //MARK: - Deletion
    ///Deletes this item from CoreData.
    public func delete() {
        MKCoreData.shared.managedObjectContext.delete(self)
        self.save()
    }
    
    ///Saves the context.
    public func save() {
        MKCoreData.shared.saveContext()
    }

    //MARK: - Updating (through MKAppleMusicManager).
    ///UpdateSettings: defines the parameters for whether to add a song to the memory.
    public struct UpdateSettings {
        //Source properties.
        ///Source from heavy rotation.
        public var sourceFromHeavyRotation = true
        ///Source from recently played.
        public var sourceFromRecentlyPlayed = true
        
        ///The number of plays to start adding items to the memory.
        public var playCountTarget = 15
        
        ///The number of tracks to take at one update into the memory.
        public var maxAddsPerAlbum = 3
        
        //Initialization
        public init(heavyRotation: Bool, recentlyPlayed: Bool, playCount: Int, maxAddsPerAlbum: Int) {
            self.sourceFromHeavyRotation = heavyRotation
            self.sourceFromRecentlyPlayed = recentlyPlayed
            self.playCountTarget = playCount
            self.maxAddsPerAlbum = maxAddsPerAlbum
        }
        
        public init() {}
    }
    
    ///Updates this playlist with a settings object.
    public func update(withSettings settings: MKMemory.UpdateSettings, andCompletion completion: @escaping UpdateCompletionHandler) {
        if settings.sourceFromHeavyRotation {
            //Run the heavy rotation request.
            MKAppleMusicManager.shared.retrieveHeavyRotation { (heavyRotationAlbums, error) in
                //Check for error.
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                //No error, check if we should run the recently played request.
                if settings.sourceFromRecentlyPlayed {
                    MKAppleMusicManager.shared.retrieveRecentlyPlayed { (recentlyPlayedAlbums, error) in
                        //Check for error.
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        //No error, process the recently played albums.
                        self.process(albums: recentlyPlayedAlbums, withUpdateSettings: settings)
                        
                        //Run the completion block.
                        completion(true)
                    }
                    self.process(albums: heavyRotationAlbums, withUpdateSettings: settings)
                    return
                }
                //Source from recently played not selected, process heavy rotation and run the completion block.
                //Process the heavy rotation albums.
                self.process(albums: heavyRotationAlbums, withUpdateSettings: settings)
                completion(true)
            }
        }
        else if settings.sourceFromRecentlyPlayed {
            //Run the Recently played request.
            MKAppleMusicManager.shared.retrieveRecentlyPlayed { (recentlyPlayedAlbums, error) in
                //Check for error.
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                //No error, continue updating the memory.
                self.process(albums: recentlyPlayedAlbums, withUpdateSettings: settings)
                completion(true)
            }
        }
        else {
            completion(false)
        }
    }
    
    ///Processes an MPMediaItemCollection (album), and adds items with a passed UpdateSettings object.
    public func process(albums: [MPMediaItemCollection?], withUpdateSettings updateSettings: UpdateSettings) {
        for album in albums {
            //Check album does not equal nil.
            guard let album = album else {
                continue
            }
            
            var loopCount = 0
            for song in album.playCountSortedItems {
                //Check if play count is greater than the target and this is one of the top songs played on this album.
                if song.playCount >= updateSettings.playCountTarget && loopCount < updateSettings.maxAddsPerAlbum {
                    if !self.contains(mpMediaItem: song) {
                        self.add(mpMediaItem: song)
                    }
                }
                //Iterate loop count.
                loopCount += 1
            }
        }
    }
    
    ///Adds a song to this memory playlist.
    public func add(mpMediaItem: MPMediaItem) {
        let newItem = MKCoreData.shared.createNewMKMemoryItem()
        newItem.persistentIdentifer = String(mpMediaItem.persistentID)
        newItem.memory = self
        newItem.save()
    }
    
    ///Removes a song from this memory playlist (if found in the items set).
    public func remove(mpMediaItem: MPMediaItem) {
        guard let items = self.items else {
            return
        }
        for item in items {
            if item.persistentIdentifer == String(mpMediaItem.persistentID) {
                item.delete()
            }
        }
    }
    
    ///Checks if this playlist already contains a song.
    public func contains(mpMediaItem: MPMediaItem) -> Bool {
        guard let items = self.items else {
            return false
        }
        for item in items {
            if item.persistentIdentifer == String(mpMediaItem.persistentID) {
                return true
            }
        }
        return false
    }
}
