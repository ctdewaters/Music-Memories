//
//  MKMemoryItem.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import CoreData
import MediaPlayer

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
