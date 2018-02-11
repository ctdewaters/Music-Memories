//
//  CoreData.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import CoreData

public class MKCoreData {
    
    public static let shared = MKCoreData()
    // MARK: - Core Data stack
    
    public lazy var persistentContainer: NSPersistentContainer = {
        
        #if os(iOS)
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let bundleID = "com.nearfuturemarketing.MemoriesKit"
        let bundle = Bundle(identifier: bundleID)!
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
        
        #elseif os(watchOS)
        let bundleID = "com.CollinDeWaters.MemoriesKit-watchOS"
        let bundle = Bundle(identifier: bundleID)!
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
        #endif
    }()
    
    // MARK: - Core Data Saving support
    
    public func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    public var managedObjectContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    
    ///MARK: - Creating new objects.
    ///Creates a new MKMemory object.
    public func createNewMKMemory() -> MKMemory {
        let newMemory = NSEntityDescription.insertNewObject(forEntityName: "MKMemory", into: self.managedObjectContext) as! MKMemory
        newMemory.storageID = String.random(withLength: 50)
        
        //Create its settings object.
        let newSettings = NSEntityDescription.insertNewObject(forEntityName: "MKMemorySettings", into: self.managedObjectContext) as! MKMemorySettings
        newMemory.settings = newSettings
        return newMemory
    }
    
    #if os(iOS)
    ///Creates a new MKMemoryItem object.
    public func createNewMKMemoryItem() -> MKMemoryItem {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "MKMemoryItem", into: self.managedObjectContext) as! MKMemoryItem
        newItem.storageID = String.random(withLength: 50)
        return newItem
    }
    #endif
    
    ///Creates a new MKImage object.
    public func createNewMKImage() -> MKImage {
        let newImage = NSEntityDescription.insertNewObject(forEntityName: "MKImage", into: self.managedObjectContext) as! MKImage
        return newImage
    }
    
    
    ///MARK: - Item fetching.
    public func fetchAllMemories() -> [MKMemory] {
        let fetchRequest = NSFetchRequest<MKMemory>(entityName: "MKMemory")
        
        do {
            let memories = try self.managedObjectContext.fetch(fetchRequest)
            return memories
        }
        catch {
            fatalError("Error retrieving memories.")
        }
    }
    
    ///MARK: - Memory deletion.
    public func deleteMemory(withID id: String) {
        let memories = self.fetchAllMemories()
        
        for memory in memories {
            if memory.storageID ?? "" == id {
                memory.delete()
                return
            }
        }
    }
    
    //MARK: - Contains function.
    public func contextContains(memoryWithID id: String) -> Bool {
        let memories = MKCoreData.shared.fetchAllMemories()
        for arrayMemory in memories {
            if arrayMemory.storageID == id {
                return true
            }
        }
        return false
    }
    
    //MARK: - Specific memory retrieval.
    public func memory(withID id: String) -> MKMemory? {
        let memories = MKCoreData.shared.fetchAllMemories()
        for memory in memories {
            if memory.storageID == id {
                return memory
            }
        }
        return nil
    }
}

extension String {
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
