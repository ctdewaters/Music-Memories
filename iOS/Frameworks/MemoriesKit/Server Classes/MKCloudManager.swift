//
//  MKServerManager.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 9/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import CoreData

///`MKCloudSettings`: A data tuple holding a user's dynamic memory settings in the server.
public typealias MKCloudSettings = (dynamicMemories: Bool?, duration: Int?, addToLibrary: Bool?)

/// `MKCloudManager`: Manages requests to and from the Music Memories server.
public class MKCloudManager {
    
    //MARK: - Properties
    
    ///A shared URL session.
    static let urlSession = URLSession()
    
    //MARK: - Notification Names
    public static let didSyncNotification = Notification.Name("MKCloudManagerDidSync")
    public static let readyForDynamicUpdateNotification = Notification.Name("MKCloudManagerReadyForDynamicUpdate")
    public static let serverSettingsDidRefreshNotification = Notification.Name("MKCloudManagerServerSettingsDidRefresh")
    
    ///This device's APNS token.
    public static var apnsToken: String?
        
    //MARK: - Authentication
    public class func authenticate(withUserID userID: String, andUserAuthToken authToken: String, firstName: String, lastName: String, andCompletion completion: ((Bool)->Void)? = nil) {
        //Set the keychain objects
        MKAuth.userID = userID
        MKAuth.userAuthToken = authToken
        
        let request = MKCloudRequest(withOperation: .authenticate, andParameters: ["firstName" : firstName, "lastName" : lastName])
        
        guard let urlRequest = request.urlRequest else { return }
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, let str = String(data: data, encoding: .ascii), error == nil else {
                completion?(false)
                return
            }
            let success = str.contains("Successfully")
            completion?(success)
        }.resume()
    }

    
    //MARK: - APNS Device Tokens
    public class func register(deviceToken: String, withCompletion completion:  ((Bool)->Void)? = nil) {
        apnsToken = deviceToken
        
        let request = MKCloudRequest(withOperation: .registerAPNSToken, andParameters: ["deviceToken" : deviceToken])
        
        guard let urlRequest = request.urlRequest else { return }
                
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, let str = String(data: data, encoding: .ascii), error == nil else {
                completion?(false)
                return
            }

            
            let success = str.contains("Successfully")
            completion?(success)
            
        }.resume()
    }
    
    //MARK: - Memory Syncing
    /// Sends the memories stored in Core Data to the MM server.
    public class func syncLocalMemories() {
        DispatchQueue.global(qos: .background).sync {
            //Retrieve the local memories.
            let memories = MKCoreData.shared.fetchAllMemories()
                        
            for memory in memories {
                self.sync(memory: memory, sendAPNS: false)
            }
        }
    }
    
    /// Retrieves memories stored in the MM server, and adds them locally if not already present or deletes them if they are present in the deleted memory table on the MM server.
    public class func syncServerMemories(updateDynamicMemory: Bool) {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .retrieveMemories, andParameters: [:])
            
            guard let urlRequest = request.urlRequest else { return }
            
            //Active memories query.
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, error == nil else { return }
                
                let decoder = JSONDecoder()
                do {
                    let cloudMemories = try decoder.decode([MKCloudMemory].self, from: data)
                    
                    let targetCount = cloudMemories.count
                    var i = 0
                    for mem in cloudMemories {
                        //Decrypt the memory.
                        mem.decrypt()
                        
                        //Sync the memory.
                        mem.saveToLocalDataStore {
                            i += 1
                            
                            if i == targetCount {
                                //Deleted memories query.
                                MKCloudManager.retreiveDeletedMemoryIDs { (ids) in
                                    //Delete the memories.
                                    for id in ids {
                                        MKCoreData.shared.deleteMemory(withID: id)
                                    }
                                    DispatchQueue.main.async {
                                        //Post updated notification.
                                        NotificationCenter.default.post(name: MKCloudManager.didSyncNotification, object: nil)
                                        if updateDynamicMemory {
                                            NotificationCenter.default.post(name: MKCloudManager.readyForDynamicUpdateNotification, object: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    print(error)
                }
            }.resume()
        }
    }
    
    /// Sends a single memory to the MM server.
    public class func sync(memory: MKMemory, sendAPNS apns: Bool, completion: (()->Void)? = nil) {
        //Create a cloud memory instance.
        let cloudMemory = MKCloudMemory(withMKMemory: memory)

        DispatchQueue.global(qos: .background).async {
            //Create the request.
            guard let jsonData = cloudMemory.jsonRepresentation else { return }                        
            
            let request = MKCloudRequest(withOperation: .postMemory, andParameters: ["apns" : "\(apns)", "apnsToken" : "\(apnsToken ?? "")"], andPostData: jsonData)
            
            if let urlRequest = request.urlRequest {
                URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                    guard error == nil else { return }
                    let str = String(data: data!, encoding: .utf8)
                    
                    print(str)
                    
                    
                    completion?()
                }.resume()
            }
        }
    }
    
    //MARK: Deletion and Restoration
    /// Deletes a memory from the MM server.
    public class func delete(memory: MKMemory) {
        DispatchQueue.global(qos: .background).async {
            //Create the request.
            guard let id = memory.storageID else { return }
            let request = MKCloudRequest(withOperation: .deleteMemory, andParameters: ["id" : id])
            guard let urlRequest = request.urlRequest else { return }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else { return }
                
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print(str)
                    
                }
            }.resume()
        }
    }
    
    /// Restores a deleted memory (if still available) on the MM server.
    public class func restore(memoryWithID id: String) {
        DispatchQueue.global(qos: .background).async {
            //Create the request.
            let request = MKCloudRequest(withOperation: .restoreMemory, andParameters: ["id" : id])
            guard let urlRequest = request.urlRequest else { return }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else { return }
                
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print(str)
                    
                    
                }
            }.resume()
        }
    }
    
    /// Retrieves the deleted memory ids from the MM server.
    public class func retreiveDeletedMemoryIDs(withCompletion completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .retrieveDeletedMemories, andParameters: [:])
            
            guard let urlRequest = request.urlRequest else {
                completion([])
                return
            }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, let ids = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String], error == nil else {
                    completion([])
                    return
                }

                completion(ids)
            }.resume()
        }
    }
    
    //MARK: - Song Deletion
    public class func delete(mkMemoryItem item: MKMemoryItem) {
        guard let memoryID = item.memory?.storageID, let title = item.title?.replacingAnd.urlEncoded, let artist = item.artist?.replacingAnd.urlEncoded, let album = item.albumTitle?.replacingAnd.urlEncoded else { return }
        
        //Create a cloud song with the memory item.
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .deleteSong, andParameters: ["title" : title, "album" : album, "artist" : artist, "memoryID" : memoryID])
            
            guard let urlRequest = request.urlRequest else { return }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, error == nil else { return }
                
                let str = String(data: data, encoding: .utf8)
                print(str)
                
            }.resume()
        }
    }
    
    //MARK: - Images
    private static var currentImageIDsUploading = [String]()
    public class func upload(mkImage image: MKImage) {
        //Create a new MKImage object with it's own MOC.
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        moc.perform {
            guard let tImage = moc.object(with: image.objectID) as? MKImage else { return }
            //Create a cloud image object.
            let cloudImage = MKCloudImage(withMKImage: tImage)
            guard let data = cloudImage.data, let memoryID = cloudImage.memoryID, let id = cloudImage.id else { return }
            
            if !currentImageIDsUploading.contains(id) {
                currentImageIDsUploading.append(id)
                
                //Create the request.
                let request = MKCloudRequest(withOperation: .uploadImage, andParameters: ["imageID" : id, "memoryID" : memoryID], andPostData: data, withFileName: "\(id).mkimage")
                
                guard let urlRequest = request.urlRequest else {
                    self.currentImageIDsUploading = self.currentImageIDsUploading.filter { $0 != id }
                    return
                }
                URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                    self.currentImageIDsUploading = self.currentImageIDsUploading.filter { $0 != id }
                    guard error == nil else {
                        return
                    }
                }.resume()
            }
        }
    }
    
    private static var currentImageIDsDownloading = [String]()
    public class func download(imageWithID id: String, forMemory memory: MKMemory) {
        memory.managedObjectContext?.perform {
            
            if !self.currentImageIDsDownloading.contains(id) && !MKCoreData.shared.context(memory.managedObjectContext!, containsImageWithID: id) {
                self.currentImageIDsDownloading.append(id)
                
                
                guard let url = URL(string: "\(MKCloudRequest.memoryImageURL)\(id).mkimage"), let memoryID = memory.storageID else { return }
                
                URLSession.shared.dataTask(with: url) { (data, response, error) in
                    guard let data = data, error == nil else { return }
                    self.currentImageIDsDownloading = self.currentImageIDsDownloading.filter { $0 != id }
                    
                    //Create cloud image object.
                    let cloudImage = MKCloudImage(withData: data, id: id, memoryID: memoryID)
                    
                    cloudImage.save(toMemory: memory)
                    
                }.resume()
            }
            else {
                print("IMAGE ALREADY PRESENT!")
            }
        }
    }
    
    /// Retrieves the IDs of images for a given memory.
    /// - Parameter memoryID: The id to retreive image ids for.
    /// - Parameter completion: A completion block, supplied with the image IDs and deleted image IDs for the memory.
    class func retrieveImageIDs(forMemoryWithID memoryID: String, andCompletion completion: @escaping ([String], [String]) -> Void) {
        let request = MKCloudRequest(withOperation: .retrieveImages, andParameters: ["memoryID" : memoryID])
        guard let urlRequest = request.urlRequest else {
            completion([],[])
            return
        }
                    
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion([],[])
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [String]] {
                guard let imageIDs = json["imageIDs"], let deletedImageIDs = json["deletedImageIDs"] else {
                    completion([],[])
                    return
                }
                
                completion(imageIDs, deletedImageIDs)
            }
        }.resume()
    }
    
    //MARK: - Image Deletion
    /// Sends a request to delete a local MKImage from the server.
    /// - Parameter imageID: The local MKImage ID to delete.
    /// - Parameter memoryID: The local MKMemory ID, which the image is associated with.
    public class func delete(imageID: String, memoryID: String) {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .deleteImage, andParameters: ["imageID" : imageID, "memoryID" : memoryID])
            guard let urlRequest = request.urlRequest else { return }
                        
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, error == nil else {
                    return
                }
                                
            }.resume()
        }
    }
    
    //MARK: - User Settings
    /// Retrieves the settings for the authenticated user.
    /// - Parameter completion: A completion block, supplied with a tuple of the settings data, which is ran after the request has completed.
    public class func retrieveUserSettings(withCompletion completion: @escaping (MKCloudSettings?)->Void) {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .retrieveSettings, andParameters: [:])
            guard let urlRequest = request.urlRequest else { return }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                
                //Create the JSON object with the data.
                guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    completion(nil)
                    return
                }
                            
                print(json)
                //Extract the settings data from the JSON object, and set it to the tuple
                let dmRaw = json["dynamicMemories"] as? String
                let duration = json["dynamicMemoryDuration"] as? String
                let addToLibraryRaw = json["addMemoriesToLibrary"] as? String
                
                var dynamicMemories: Bool?
                if let dmRaw = dmRaw, let dm = Int(dmRaw) {
                    dynamicMemories = Bool(truncating: NSNumber(integerLiteral: dm))
                }
                var aTL: Bool?
                if let addToLibraryRaw = addToLibraryRaw, let addToLibrary = Int(addToLibraryRaw) {
                    aTL = Bool(truncating: NSNumber(integerLiteral: addToLibrary))
                }
                let d = Int(duration ?? "")
                
                //Create a settings data tuple.
                let settingsData: MKCloudSettings = (dynamicMemories: dynamicMemories, duration: d, addToLibrary: aTL)
                
                //Run the completion block.
                completion(settingsData)
            }.resume()
        }
    }
    
    public class func updateUserSettings(dynamicMemories: Bool, duration: Int, addToLibrary: Bool) {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .updateSettings, andParameters: ["dynamicMemories" : "\(NSNumber(booleanLiteral: dynamicMemories))", "duration" : String(duration), "addToLibrary" : "\(NSNumber(booleanLiteral: addToLibrary))", "apnsToken" : apnsToken ?? ""])
            guard let urlRequest = request.urlRequest else { return }
            
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard error == nil else { return }
            }.resume()
        }
    }
    
    //MARK: - APNS Handling
    
    ///If true, the next APNS payload will not be handled.
    public static var lockAPNS = false
    
    public class func handle(apnsUserInfo userInfo: [AnyHashable: Any]) {
        //Check if the APNS lock is on.
        if lockAPNS {
            //Turn off the lock and return.
            lockAPNS = false
            return
        }
        
        if let actionCode = userInfo["actionCode"] as? String, UIApplication.shared.applicationState == UIApplication.State.active {
            print("ACTION CODE WITH APNS: \(actionCode)")
            
            if actionCode == MKCloudAPNSAction.downloadImage.rawValue {
                //Image download request.
                guard let memoryID = userInfo["memoryID"] as? String, let imageID = userInfo["imageID"] as? String else { return }
                if let memory = MKCoreData.shared.memory(withID: memoryID) {
                    
                    MKCloudManager.download(imageWithID: imageID, forMemory: memory)
                }
                return
            }
            else if actionCode == MKCloudAPNSAction.deleteImage.rawValue {
                //Image deletion notification.
                guard let imageID = userInfo["imageID"] as? String, let mkImage = MKCoreData.shared.image(withID: imageID) else { return }
                
                mkImage.delete()
                
                //Post update notification.
                NotificationCenter.default.post(name:  MKCloudManager.didSyncNotification, object: nil)
                return
            }
            else if actionCode == MKCloudAPNSAction.refreshSettings.rawValue {
                //Load settings.
                MKCloudManager.retrieveUserSettings { (settings) in
                    guard let settings = settings else { return }
                    //Post the settings did refresh notification.
                    let userInfo = ["settings" : settings] as [String : Any]
                    NotificationCenter.default.post(name: MKCloudManager.serverSettingsDidRefreshNotification, object: nil, userInfo: userInfo)
                }
                return
            }
            MKCloudManager.syncServerMemories(updateDynamicMemory: false)
        }
    }
}

private enum MKCloudAPNSAction: String {
    case downloadImage = "256", deleteImage = "512", refresh = "10000", refreshSettings = "20000"
}
