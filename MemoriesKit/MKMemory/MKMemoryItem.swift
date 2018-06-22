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
    ///The artist.
    @NSManaged public var artist: String?
    
    ///The title.
    @NSManaged public var title: String?
    
    //The album title.
    @NSManaged public var albumTitle: String?

    ///The persistent identifer of this item, used to retrieve from the MediaPlayer library.
    @NSManaged public var persistentIdentifer: String?
    
    ///The linked MKMemory playlist.
    @NSManaged public var memory: MKMemory?
    
    ///The ID this memory item is stored with.
    @NSManaged public var storageID: String!
    
    //MARK: - `MPMediaItem` retrieval.
    ///The linked MPMediaItem.
    public var mpMediaItem: MPMediaItem? {
        //Check if the media item has been retrieved already.
        if let localMPMediaItem = self.mpMediaItemReference {
            return localMPMediaItem
        }
        
        guard let persistentID = self.persistentIdentifer else {
            return nil
        }
        guard let intPersistentID = Int(persistentID) else {
            return nil
        }
        
        let persistentIDPredicate = MPMediaPropertyPredicate(value: NSNumber(value: intPersistentID), forProperty: MPMediaItemPropertyPersistentID, comparisonType: .equalTo)
        let songQuery = MPMediaQuery.songs()
        songQuery.addFilterPredicate(persistentIDPredicate)
        
        guard let mediaItem = songQuery.items?.first else {
            //Media item not found with persistent ID, try to find it with the other stored properties.
            let titlePredicate = MPMediaPropertyPredicate(value: self.title ?? "", forProperty: MPMediaItemPropertyTitle, comparisonType: .equalTo)
            let artistPredicate = MPMediaPropertyPredicate(value: self.artist ?? "", forProperty: MPMediaItemPropertyArtist, comparisonType: .equalTo)
            let albumPredicate = MPMediaPropertyPredicate(value: self.albumTitle ?? "", forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .equalTo)
            
            songQuery.addFilterPredicate(titlePredicate)
            songQuery.addFilterPredicate(artistPredicate)
            songQuery.addFilterPredicate(albumPredicate)
            songQuery.removeFilterPredicate(persistentIDPredicate)
            
            let mediaItem = songQuery.items?.first
            
            //Save the media item properties, if they aren't saved yet.
            if self.title == nil {
                self.save(propertiesOfMediaItem: mediaItem)
            }
            
            self.mpMediaItemReference = mediaItem
            return mediaItem
        }
        
        //Save the media item properties, if they aren't saved yet.
        if self.title == nil {
            self.save(propertiesOfMediaItem: mediaItem)
        }
        
        self.mpMediaItemReference = mediaItem
        return mediaItem
    }
    
    ///A private MPMediaItem reference.
    private var mpMediaItemReference: MPMediaItem?
    
    //MARK: - `MPMediaItem` property saving.
    //Saves the properties of a media item.
    public func save(propertiesOfMediaItem mediaItem: MPMediaItem?) {
        print("SAVING MEDIA ITEM \(mediaItem)")
        guard let mediaItem = mediaItem else {
            return
        }
        
        //Set properties.
        self.title = mediaItem.title
        self.albumTitle = mediaItem.albumTitle
        self.artist = mediaItem.artist
        self.persistentIdentifer = String(mediaItem.persistentID)
        
        guard self.title != nil, self.albumTitle != nil, self.artist != nil, self.persistentIdentifer != nil else {
            return
        }
        
        //Save.
        self.save()
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
