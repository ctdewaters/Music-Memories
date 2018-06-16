//
//  MKMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData
import WatchConnectivity

#if os(iOS)
import MediaPlayer
#endif

///`MKMemory`: Represents a memory playlist.
public class MKMemory: NSManagedObject {
    
    var context: NSManagedObjectContext!
    
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
    
    //MARK: - TransferSetting: tells the destination what to do with the sent memory.
    public enum TransferSetting: Int {
        case update = 100, delete = 200, playback = 300, requestImage = 400
    }
    
    public class func handleTransfer(withWCSession wcSession: WCSession?, withDictionary memoryDict: [String: Any], withCompletion completion: @escaping ()->Void) {
        //Get the storage ID for the transferred memory.
        if let storageID = memoryDict["storageID"] as? String {
            //Get the transfer setting.
            if let transferSettingRaw = memoryDict["transferSetting"] as? Int {
                if let transferSetting = MKMemory.TransferSetting(rawValue: transferSettingRaw) {
                    if transferSetting == .update {
                        #if os(watchOS)
                        if !MKCoreData.shared.contextContains(memoryWithID: storageID) {
                            //Create the memory.
                            
                            let memory = MKMemory(withDictionary: memoryDict)
                            print(memory.storageID)
                            memory.save()
                        }
                        #endif
                    }
                    else if transferSetting == .delete {
                        //Delete the object with the transferred storage ID.
                        MKCoreData.shared.deleteMemory(withID: storageID)
                    }
                    else if transferSetting == .playback {
                        #if os(iOS)
                        //Playback setting selected.
                        //Retrieve the local reference to the memory.
                        if let localMemory = MKCoreData.shared.memory(withID: storageID) {
                            MKMusicPlaybackHandler.play(memory: localMemory)
                        }
                        #endif
                    }
                    else if transferSetting == .requestImage {
                        if let localMemory = MKCoreData.shared.memory(withID: storageID) {
                            localMemory.sendImageToCompanionDevice(withSession: wcSession)
                        }
                    }
                    
                    //Run the completion block.
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
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
    
    //MARK: - Saving and Deleting.
    ///Deletes this memory from CoreData.
    public func delete() {
        MKCoreData.shared.managedObjectContext.delete(self)
        self.save()
    }
    
    ///Saves the context.
    public func save() {
        MKCoreData.shared.saveContext()
    }
    
    //MARK: - Initialization
    ///Initializes a blank object.
    public convenience init() {
        self.init(entity: MKMemory.entity(), insertInto: MKCoreData.shared.managedObjectContext)
        
    }
    
    #if os(watchOS)
    ///Initializes with a dictionary.
    public convenience init(withDictionary dictionary: [String: Any]) {
        self.init(entity: MKMemory.entity(), insertInto: MKCoreData.shared.managedObjectContext)
        
        self.decode(fromDictionary: dictionary)
    }
    #endif
    
    #if os(iOS)
    ///Removes all objects no longer present in the user's library.
    public func removeAllSongsNotInLibrary() {
        for item in self.items ?? [] {
            if item.mpMediaItem == nil {
                item.delete()
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
    #endif
    
    //MARK: - WatchConnectivity.
    ///Sends this memory to the user's watch immediately using the messaging feature.
    public func messageToCompanionDevice(withSession session: WCSession?, withTransferSetting transferSetting: MKMemory.TransferSetting = .update) {
        if session?.activationState == WCSessionActivationState.activated {
            if transferSetting == .delete || transferSetting == .playback || transferSetting == .requestImage {
                let message = ["storageID" : self.storageID, "transferSetting" : transferSetting.rawValue] as [String : Any]
                session?.sendMessage(message, replyHandler: nil, errorHandler: { (error) in
                    //Add to the user info queue, since we can't reach the watch.
                    self.addToUserInfoQueue(withSession: session, withTransferSetting: transferSetting)
                })
                return
            }
            
            #if os(iOS)
            var message = self.encoded
            message["transferSetting"] = transferSetting.rawValue
            session?.sendMessage(message, replyHandler: nil, errorHandler: { (error) in
                //Add to the user info queue, since we can't reach the watch.
                self.addToUserInfoQueue(withSession: session, withTransferSetting: transferSetting)
            })
            #endif
        }
    }
    
    ///Sends this memory to the user's Watch using the user info feature.
    public func addToUserInfoQueue(withSession session: WCSession?, withTransferSetting transferSetting: MKMemory.TransferSetting = .update) {
        if session?.activationState == WCSessionActivationState.activated {
            if transferSetting == .delete || transferSetting == .playback || transferSetting == .requestImage {
                let userInfo = ["storageID" : self.storageID, "transferSetting" : transferSetting.rawValue] as [String : Any]
                session?.transferUserInfo(userInfo)
                return
            }
            #if os(iOS)
            var userInfo = self.encoded
            userInfo["transferSetting"] = transferSetting.rawValue
            session?.transferUserInfo(userInfo)
            #endif
        }
    }
    
    ///Sends a random image to the user's Watch
    private func sendImageToCompanionDevice(withSession session: WCSession?) {
        if let firstImage = self.images?.first {
            if let uiImage = firstImage.uiImage(withSize: CGSize.square(withSideLength: 250)) {
                if let compressedImageData = uiImage.compressedData(withQuality: 0.001) {
                    let context = ["memoryID" : self.storageID ?? "", "imageData" : compressedImageData] as [String : Any]
                    do {
                        try session?.updateApplicationContext(context)
                    }
                    catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    #if os(iOS)
    //MARK: - MPMediaItem functions.
    
    ///Adds a song to this memory playlist.
    public func add(mpMediaItem: MPMediaItem) {
        let newItem = MKCoreData.shared.createNewMKMemoryItem()
        newItem.persistentIdentifer = String(mpMediaItem.persistentID)
        newItem.memory = self
        newItem.save()
        
        //Check if we should add to the associated playlist.
        if let sync = self.settings?.syncWithAppleMusicLibrary.boolValue {
            if sync {
                self.retrieveAssociatedPlaylist { (playlist) in
                    playlist?.add([mpMediaItem], completionHandler: nil)
                }
            }
        }
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
    
    #if os(watchOS)
    //MARK: - Decoding.
    ///Decodes from a dictionary.
    public func decode(fromDictionary dictionary: [String: Any]) {
        if let title = dictionary["title"] as? String {
            self.title = title
        }
        if let desc = dictionary["desc"] as? String {
            self.desc = desc
        }
        if let storageID = dictionary["storageID"] as? String {
            self.storageID = storageID
        }
        if let startDate = dictionary["startDate"] as? Date {
            self.startDate = startDate
        }
        if let endDate = dictionary["endDate"] as? Date {
            self.endDate = endDate
        }
        if let uuidString = dictionary["uuidString"] as? String {
            self.uuidString = uuidString
        }
        if let source = dictionary["source"] as? NSNumber {
            self.source = source
        }
        //Items
        if let items = dictionary["items"] as? [[String: Any]] {
            for item in items {
                let mkMemoryItem = MKMemoryItem(withDictionary: item)
                mkMemoryItem.memory = self
            }
        }
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
