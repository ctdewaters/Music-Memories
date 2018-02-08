//
//  MKMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData

#if os(iOS)
import MediaPlayer
#endif

///Represents a memory playlist.
public class MKMemory: NSManagedObject {
    
    /// The completion handler that is called when an Apple Music Get Recently Played API call completes.
    public typealias UpdateCompletionHandler = (_ success: Bool) -> Void

    ///The name of this memory.
    @NSManaged public var title: String?
    
    //A description of the memory.
    @NSManaged public var desc: String?
    
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
    
    //The UUID of the associated playlist in the user's Apple Music library.
    @NSManaged public var uuidString: String?
    
    //The source integer.
    @NSManaged public var source: NSNumber?
    
    ///The settings for this memory.
    @NSManaged public var settings: MKMemorySettings?
    
    //The source type (mapped from the stored source integer).
    public var sourceType: SourceType {
        return SourceType(rawValue: self.source?.intValue ?? 0) ?? .past
    }
    
    ///Determines whether or not this memory can be automatically updated in the background.
    public var autoUpdatable: Bool {
        guard let endDate = self.endDate else {
            return false
        }
        return Date().isBefore(date: endDate)
    }
    
    //MARK: - SourceType: the source type for the memory.
    public enum SourceType: Int {
        case past, current, calendar
        
        public var isEditable: Bool {
            if self == .past {
                return true
            }
            return false
        }
    }
    
    #if os(iOS)
    //MARK: - MPMediaItems list.
    public var mpMediaItems: Array<MPMediaItem>? {
        guard let items = self.items else {
            return nil
        }
        var returnedItems = Array<MPMediaItem>()
        for item in items {
            if let mediaItem = item.mpMediaItem {
                returnedItems.append(mediaItem)
            }
        }
        return returnedItems
    }
    #endif
    
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
    
    #if os(iOS)
    ///Removes all objects no longer present in the user's library.
    public func removeAllSongsNotInLibrary() {
        for item in self.items ?? [] {
            if item.mpMediaItem == nil {
                item.delete()
            }
        }
    }
    
    //MARK: - iCloud Music Library Syncronization
    ///Retrives or creates the associated playlist in the user's iCloud Music Library.
    public func retrieveAssociatedPlaylist(withCompletion completion: @escaping (MPMediaPlaylist?) -> Void ) {
        var uuid: UUID?
        var playlistCreationMetadata: MPMediaPlaylistCreationMetadata?
        if let uuidString = self.uuidString {
            //Playlist already created.
            uuid = UUID(uuidString: uuidString)
        }
        else {
            //Playlist not yet created.
            uuid = UUID()
            //Save the UUID to the memory, and save.
            self.uuidString = uuid?.uuidString
            self.save()
            //Setup the creation metadata.
            playlistCreationMetadata = MPMediaPlaylistCreationMetadata(name: self.title ?? "Music Memory")
            playlistCreationMetadata?.descriptionText = self.desc ?? "Playlist created in Music Memories."
        }
        
        MPMediaLibrary.default().getPlaylist(with: uuid!, creationMetadata: playlistCreationMetadata) { (playlist, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            //Run the completion block
            completion(playlist)
        }
    }
    
    ///Adds all songs to the associated playlist.
    public func syncToUserLibrary(withCompletion completion: (()->Void)? = nil) {
        guard let updateWithAppleMusic = self.settings?.updateWithAppleMusic else {
            completion?()
            return
        }
        //Check if the update with apple music setting is on.
        if updateWithAppleMusic {
            self.retrieveAssociatedPlaylist { playlist in
                playlist?.add(self.mpMediaItems ?? [], completionHandler: { (error) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    //Run the completion block.
                    completion?()
                })
            }
            return
        }
        completion?()
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
            if let itemMP = item.mpMediaItem {
                if itemMP == mpMediaItem {
                    return true
                }
            }
        }
        return false
    }
    
    #endif
}

public extension Date {
    public func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self).rawValue * self.compare(date2).rawValue >= 0
    }
    
    public func isBefore(date: Date) -> Bool {
        if date.compare(self) == .orderedDescending {
            return true
        }
        return false
    }
}
