//
//  CoreData.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import CoreData

/// `MKCoreData`: Handles saving, deleting, and editing objects in persistent storage.
public class MKCoreData {
    public static let shared = MKCoreData()
    
    // MARK: - Core Data stack
    
    ///The persistent container.
    public lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let bundle = Bundle.main
        let modelURL = bundle.url(forResource: "MemoriesKit", withExtension: "momd")!
        let objectModel = NSManagedObjectModel(contentsOf: modelURL)!

        let container = NSPersistentContainer(name: "MemoriesKit", managedObjectModel: objectModel)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    ///The managed object context.
    public var managedObjectContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    // MARK: - Saving
    
    ///Saves current context to persistent storage.
    public func saveContext () {
        DispatchQueue.main.async {
            let context = self.managedObjectContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    print("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    //MARK: - Object Creation
    
    ///Creates a new MKMemory object.
    public func createNewMKMemory() -> MKMemory {
        
        let newMemory = NSEntityDescription.insertNewObject(forEntityName: "MKMemory", into: self.managedObjectContext) as! MKMemory
        newMemory.storageID = String.random(withLength: 50)
        
        //Create its settings object.
        let newSettings = NSEntityDescription.insertNewObject(forEntityName: "MKMemorySettings", into: self.managedObjectContext) as! MKMemorySettings
        newMemory.settings = newSettings
        return newMemory
    }
    
    /// Creates a new Dynamic MKMemory object.
    /// - Parameter endDate: The date the dynamic memory will no longer be updated.
    /// - Parameter syncToLibrary: If true, the dynamic memory will sync with a playlist in Apple Music.
    public func createNewDynamicMKMemory(withEndDate endDate: Date, syncToLibrary: Bool) -> MKMemory? {
        if MKCoreData.shared.fetchCurrentDynamicMKMemory() != nil {
            //Don't create new if there is already a current dynamic memory.
            return nil
        }

        let newMemory = self.createNewMKMemory()
        newMemory.isDynamic = NSNumber(value: true)
        newMemory.startDate = Date()
        newMemory.endDate = endDate
        newMemory.title = "Dynamic Memory \(Date().shortString)"
        
        if syncToLibrary {
            newMemory.settings?.syncWithAppleMusicLibrary = true
            newMemory.syncToUserLibrary()
        }
        else {
            newMemory.settings?.syncWithAppleMusicLibrary = false
        }
        
        newMemory.save(sync: true, withAPNS: false)
        return newMemory
    }
    
    ///Creates a new MKMemoryItem object.
    public func createNewMKMemoryItem() -> MKMemoryItem {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "MKMemoryItem", into: self.managedObjectContext) as! MKMemoryItem
        newItem.storageID = String.random(withLength: 50)
        return newItem
    }
    
    ///Creates a new MKImage object.
    public func createNewMKImage() -> MKImage {
        let newImage = NSEntityDescription.insertNewObject(forEntityName: "MKImage", into: self.managedObjectContext) as! MKImage
        return newImage
    }
    
    //MARK: - Fetching
    
    ///Fetches all `MKMemory` objects in persistent storage.
    public func fetchAllMemories() -> [MKMemory] {
        let fetchRequest = NSFetchRequest<MKMemory>(entityName: "MKMemory")
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let memories = try self.managedObjectContext.fetch(fetchRequest)
            
            for memory in memories {
                memory.context = self.managedObjectContext
            }
            MKCoreData.shared.saveContext()
            return memories
        }
        catch {
            fatalError("Error retrieving memories.")
        }
    }
    
    ///Fetches the currently updating dynamic memory.
    public func fetchCurrentDynamicMKMemory() -> MKMemory? {
        let allMemories = self.fetchAllMemories()
        
        for memory in allMemories {
            if memory.isDynamicMemory {
                if let startDate = memory.startDate, let endDate = memory.endDate {
                    if startDate < Date() && endDate > Date() {
                        memory.context = self.managedObjectContext
                        return memory
                    }
                }
            }
        }
        return nil
    }
    
    /// Fetches a memory with a given storage ID.
    /// - Parameter id: The storage identifier to search persistent storage with.
    public func memory(withID id: String) -> MKMemory? {
        let memories = MKCoreData.shared.fetchAllMemories()
        for memory in memories {
            if memory.storageID == id {
                return memory
            }
        }
        return nil
    }
    
    //MARK: - Deleting
    public func deleteMemory(withID id: String) {
        let memories = self.fetchAllMemories()
        
        for memory in memories {
            if memory.storageID ?? "" == id {
                memory.delete()
                return
            }
        }
    }
    
    //MARK: - Contains
    
    /// Searches `MKMemory` objects in persistent storage with a geven identifier.
    /// - Parameter id: The storage identifier to search with.
    public func contextContains(memoryWithID id: String) -> Bool {
        let memories = MKCoreData.shared.fetchAllMemories()
        for arrayMemory in memories {
            if arrayMemory.storageID == id {
                return true
            }
        }
        return false
    }
}

//MARK: - Extensions

extension String {
    /// Creates a random alphanumerical string with a given length.
    /// - Parameter length: The length at which to create the random string.
    static func random(withLength length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
}

extension Date {
    var shortString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        return dateFormatter.string(from: self)
    }
    
    var longString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: self)
    }
    
    var medString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: self)
    }
}
