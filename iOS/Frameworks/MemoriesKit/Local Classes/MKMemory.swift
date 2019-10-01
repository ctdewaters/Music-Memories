//
//  MKMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData
import UserNotifications

import MediaPlayer

///`MKMemory`: Represents a memory playlist.
public class MKMemory: NSManagedObject {
        
    /// The completion handler that is called when an Apple Music Get Heavy Rotation API call completes.
    public typealias UpdateCompletionHandler = (_ success: Bool) -> Void

    //MARK: - Properties.
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
    
    ///Determines if this memory should be dynamically updated in the background.
    @NSManaged public var isDynamic: NSNumber?
    
    
    public var isDynamicMemory: Bool {
        guard let boolValue = self.isDynamic?.boolValue else {
            return false
        }
        return boolValue
    }
    
    //The source type (mapped from the stored source integer).
    public var sourceType: SourceType {
        return SourceType(rawValue: self.source?.intValue ?? 0) ?? .past
    }
    
    ///The IDs of deleted memories.
    public static var deletedIDs: [String] {
        get {
            return UserDefaults.standard.array(forKey: "mkMemoryDeletedIDs") as? [String] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mkMemoryDeletedIDs")
        }
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
    
    //MARK: - UserNotifications.
    ///Notification content for this memory.
    public var notificationContent: UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = self.isDynamicMemory ? "New Dynamic Memory" : "Don't Forget Your Latest Memory!"
        content.body = "'\(self.title ?? "")' is available in Music Memories now!"
        content.categoryIdentifier = self.isDynamicMemory ? "dynamicMemory" : "memoryReminder"
        content.userInfo = ["startDate": self.startDate as Any, "endDate": self.endDate as Any, "memoryID": self.storageID as Any, "memoryTitle": self.title as Any]
        return content
    }
        
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
        
    //MARK: - Saving and Deleting.
    ///Deletes this memory from CoreData.
    public func delete() {
        //Append to the deleted storage ID array.
        MKMemory.deletedIDs.append(self.storageID ?? "")
        
        //Delete from the server.
        MKCloudManager.delete(memory: self)
        
        //Delete locally.
        self.managedObjectContext?.delete(self)
        self.save()
    }
    
    ///Saves the context and syncs with an APNS setting based on passed parameters.
    public func save(sync: Bool = false, withAPNS apns: Bool = false, completion: (()->Void)? = nil) {
        guard let moc = self.managedObjectContext else { return }
        MKCoreData.shared.save(context: moc)
            
        if sync {
            MKCloudManager.sync(memory: self, sendAPNS: apns, completion: completion)
        }
    }
    
    //MARK: - Initialization
    ///Initializes a blank object.
    public convenience init() {
        self.init(entity: MKMemory.entity(), insertInto: MKCoreData.shared.managedObjectContext)
        
    }
    
    ///Removes all objects no longer present in the user's library.
    public func removeAllSongsNotInLibrary() {
        let moc = self.managedObjectContext
        moc?.perform {
            for item in self.items ?? [] {
                if item.mpMediaItem == nil {
                    item.delete()
                }
            }
        }
    }
    
    //MARK: - iCloud Music Library Synchronization
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
        guard let moc = self.managedObjectContext else { return }
        moc.perform {
            
            guard let updateWithAppleMusic = self.settings?.updateWithAppleMusic else {
                completion?()
                
                return
            }
            
            
            //Check if the update with apple music setting is on.
            if updateWithAppleMusic {
                
                
                self.retrieveAssociatedPlaylist { playlist in
                    guard let playlist = playlist else {
                        completion?()
                        return
                    }
                    let mediaItems = self.mpMediaItems?.filter {
                        return !playlist.items.contains($0)
                    } ?? []
                    
                    
                    playlist.add(mediaItems, completionHandler: { (error) in
                        //Run the completion block.
                        completion?()
                    })
                }
                return
            }
            completion?()
        }
    }
    
    //MARK: - Updating (through MKAppleMusicManager).
    ///UpdateSettings: defines the parameters for whether to add a song to the memory.
    public struct UpdateSettings {
        //Source properties.
        ///Source from heavy rotation.
        public var sourceFromHeavyRotation = true
        ///Source from recently played.
        public var sourceFromRecentlyPlayed = true
        ///Source from recently added.
        public var sourceFromRecentlyAdded = true
        
        ///The number of plays to start adding items to the memory.
        public var playCountTarget = 15
        
        ///The number of tracks to take at one update into the memory.
        public var maxAddsPerAlbum = 3
        
        //Initialization
        public init(heavyRotation: Bool, recentlyPlayed: Bool, recentlyAdded: Bool, playCount: Int, maxAddsPerAlbum: Int) {
            self.sourceFromHeavyRotation = heavyRotation
            self.sourceFromRecentlyPlayed = recentlyPlayed
            self.sourceFromRecentlyAdded = recentlyAdded
            self.playCountTarget = playCount
            self.maxAddsPerAlbum = maxAddsPerAlbum
        }
        
        public init() {}
    }
    
    ///Updates this playlist with a settings object.
    public func update(withSettings settings: MKMemory.UpdateSettings, andCompletion completion: @escaping UpdateCompletionHandler) {
        DispatchQueue.global(qos: .userInteractive).async {
            if settings.sourceFromRecentlyAdded {
                var items = MPMediaQuery.retrieveItemsAdded(betweenDates: Date().addingTimeInterval(-60*60*24*7), and: Date())
                
                
                
                items = items.filter {
                    print($0.title)
                    return $0.playCount > settings.playCountTarget
                }
                for item in items {
                    self.add(mpMediaItem: item)
                }
            }
            else if settings.sourceFromRecentlyPlayed {
                //Run the Recently played request.
                MKAppleMusicManager.shared.run(requestWithSource: .recentlyPlayed) { (mkMediaItems, error, statusCode) in
                    DispatchQueue.global(qos: .userInteractive).async {
                        //Check for error.
                        guard error == nil else {
                            print(error!.localizedDescription)
                            return
                        }
                        
                        let recentlyPlayedAlbums = (mkMediaItems ?? []).map {
                            return  $0.albumCollection
                        }
                        
                        //No error, continue updating the memory.
                        self.process(albums: recentlyPlayedAlbums, withUpdateSettings: settings)
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                }
            }
            else {
                completion(false)
            }
        }
    }
    
    ///Processes an MPMediaItemCollection (album), and adds items with a passed UpdateSettings object.
    public func process(albums: [MPMediaItemCollection?], withUpdateSettings updateSettings: UpdateSettings) {
        print(albums)
        let albums = albums.filter { $0 != nil }.map { $0! }
        
        for album in albums {
            var loopCount = 0
            for song in album.playCountSortedItems {
                //Check if play count is greater than the target and this is one of the top songs played on this album.
                if song.playCount >= updateSettings.playCountTarget && loopCount < updateSettings.maxAddsPerAlbum {
                    self.add(mpMediaItem: song)
                }
                //Iterate loop count.
                loopCount += 1
            }
        }
    }
    
    //MARK: - Encoding.
    ///Encodes to a dictionary for transfer to watchOS.
    public var encoded: [String: Any] {
        var encodedDict = [String: Any]()
        encodedDict["title"] = self.title
        encodedDict["desc"] = self.desc
        encodedDict["storageID"] = self.storageID
        encodedDict["startDate"] = self.startDate
        encodedDict["endDate"] = self.endDate
        encodedDict["uuidString"] = self.uuidString
        encodedDict["source"] = self.source
        
        //Items
        encodedDict["items"] = self.items?.map{
            return $0.encoded
        }
        
        return encodedDict
    }
    //MARK: - MPMediaItem functions
    
    ///Adds a song to this memory playlist.
    public func add(mpMediaItem: MPMediaItem) {
        guard let moc = self.managedObjectContext else { return }
        if self.contains(mpMediaItem: mpMediaItem) {
            return
        }
        
        let newItem = MKCoreData.shared.createNewMKMemoryItem(inContext: moc)
        newItem.save(propertiesOfMediaItem: mpMediaItem)
        
        newItem.memory = self
        
        print(newItem.memory?.title)
        print(newItem.managedObjectContext)
        
        //Check if we should add to the associated playlist.
        if let sync = self.settings?.syncWithAppleMusicLibrary.boolValue {
            if sync {
                self.retrieveAssociatedPlaylist { (playlist) in
                    guard let items = playlist?.items else { return }
                    if !items.contains(mpMediaItem) {
                        playlist?.add([mpMediaItem], completionHandler: nil)
                    }
                }
            }
        }
    }
    
    ///Removes a song from this memory playlist (if found in the items set).
    public func remove(mpMediaItem: MPMediaItem) {
        guard let moc = self.managedObjectContext else { return }
        moc.perform {
            guard let items = self.items else {
                return
            }
            for item in items {
                if item.persistentIdentifer == String(mpMediaItem.persistentID) {
                    item.delete()
                }
            }
        }
    }
    
    ///Checks if this playlist already contains a song.
    public func contains(mpMediaItem: MPMediaItem) -> Bool {
        guard let mediaItems = self.mpMediaItems  else { return false }
        return mediaItems.contains(mpMediaItem)
    }
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
