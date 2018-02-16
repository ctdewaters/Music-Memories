//
//  MKMemoryItem.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData

#if os(iOS)
import MediaPlayer

//MARK: - iOS Representation.
///Represents a song in a MKMemory playlist.
public class MKMemoryItem: NSManagedObject {
    ///The persistent identifer of this item, used to retrieve from the MediaPlayer library.
    @NSManaged public var persistentIdentifer: String?
    
    ///The linked MKMemory playlist.
    @NSManaged public var memory: MKMemory?
    
    ///The ID this memory item is stored with.
    @NSManaged public var storageID: String!
    
    //MARK: - MPMediaItem retrieval.
    ///The linked MPMediaItem.
    public var mpMediaItem: MPMediaItem? {
        guard let persistentID = self.persistentIdentifer else {
            return nil
        }
        guard let intPersistentID = Int(persistentID) else {
            return nil
        }
        
        let persistentIDPredicate = MPMediaPropertyPredicate(value: NSNumber(value: intPersistentID), forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo)
        let songQuery = MPMediaQuery.songs()
        songQuery.addFilterPredicate(persistentIDPredicate)
        if songQuery.items != nil && songQuery.items!.count > 0 {
            return songQuery.items![0]
        }
        return nil
    }
    
    //MARK: - Encoding.
    ///Encodes basic media item data to a dictionary.
    public var encoded: [String: Any] {
        var encodedDict = [String: Any]()
        let mpMediaItem = self.mpMediaItem
        encodedDict["artist"] = mpMediaItem?.albumArtist
        encodedDict["title"] = mpMediaItem?.title
        encodedDict["albumTitle"] = mpMediaItem?.albumTitle
        
        return encodedDict
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
}

public extension MPMediaItem {
    ///A MKMemoryItem object to add to an MKMemory.
    public var mkMemoryItem: MKMemoryItem {
        let item = MKCoreData.shared.createNewMKMemoryItem()
        item.persistentIdentifer = "\(self.persistentID)"
        
        return item
    }
}
#endif

//MARK: - watchOS Representation.
#if os(watchOS)
public class MKMemoryItem: NSManagedObject {
    //MARK: - Properties.
     ///The artist.
    @NSManaged public var artist: String?
    
    ///The title.
    @NSManaged public var title: String?
    
    //The album title.
    @NSManaged public var albumTitle: String?
    
    ///The linked MKMemory playlist.
    @NSManaged public var memory: MKMemory?
    
    ///The ID this memory item is stored with.
    @NSManaged public var storageID: String!
    
    //MARK: - Initialization.
    public convenience init() {
        self.init(entity: MKMemoryItem.entity(), insertInto: MKCoreData.shared.managedObjectContext)
    }
    
    public convenience init(withDictionary dictionary: [String: Any]) {
        self.init(entity: MKMemoryItem.entity(), insertInto: MKCoreData.shared.managedObjectContext)
        self.decode(fromDictionary: dictionary)
    }
    
    //MARK: - Saving.
    public func save() {
        MKCoreData.shared.saveContext()
    }
    
    //MARK: - Decoding.
    private func decode(fromDictionary dictionary: [String: Any]) {
        if let artist = dictionary["artist"] as? String {
            self.artist = artist
        }
        if let title = dictionary["title"] as? String {
            self.title = title
        }
        if let albumTitle = dictionary["albumTitle"] as? String {
            self.albumTitle = albumTitle
        }
    }
}
#endif
