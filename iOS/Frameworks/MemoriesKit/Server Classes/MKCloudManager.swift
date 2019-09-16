//
//  MKServerManager.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 9/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

/// `MKCloudManager`: Manages requests to and from the Music Memories server.
public class MKCloudManager {
    
    static let urlSession = URLSession()
    
    public static let didSyncNotification = Notification.Name("MKCloudManagerDidSync")
    
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
    public class func syncServerMemories() {
        DispatchQueue.global(qos: .background).async {
            let request = MKCloudRequest(withOperation: .retrieveMemories, andParameters: [:])
            
            guard let urlRequest = request.urlRequest else { return }
            
            //Active memories query.
            URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data, error == nil else { return }
                let str = String(data: data, encoding: .utf8)
                                
                let decoder = JSONDecoder()
                do {
                    let cloudMemories = try decoder.decode([MKCloudMemory].self, from: data)
                    for mem in cloudMemories {
                        //Decrypt the memory.
                        mem.decrypt()
                        
                        //Sync the memory.
                        mem.sync()
                    }
                    
                    DispatchQueue.main.async {
                        //Post updated notification.
                        NotificationCenter.default.post(name: MKCloudManager.didSyncNotification, object: nil)
                    }

                    //Deleted memories query.
                    MKCloudManager.retreiveDeletedMemoryIDs { (ids) in
                        DispatchQueue.main.async {
                            //Delete the memories.
                            for id in ids {
                                MKCoreData.shared.deleteMemory(withID: id)
                            }
                            //Post updated notification.
                            NotificationCenter.default.post(name: MKCloudManager.didSyncNotification, object: nil)
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
    public class func sync(memory: MKMemory, sendAPNS apns: Bool) {
        DispatchQueue.global(qos: .background).async {
            //Create a cloud memory instance.
            let cloudMemory = MKCloudMemory(withMKMemory: memory)
                            
            //Create the request.
            guard let jsonData = cloudMemory.jsonRepresentation else { return }
            let str = String(data: jsonData, encoding: .utf8)
            let request = MKCloudRequest(withOperation: .postMemory, andParameters: ["apns" : "\(apns)"], andPostData: jsonData)
            if let urlRequest = request.urlRequest {
                URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                    guard error == nil else { return }
                            
                }.resume()
            }
        }
    }
    
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
}