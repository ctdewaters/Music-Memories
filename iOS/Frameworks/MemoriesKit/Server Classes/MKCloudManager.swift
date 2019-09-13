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
            
            print(str)
            
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
            
            print(str)
            let success = str.contains("Successfully")
            completion?(success)
            
        }.resume()
    }
    
    //MARK: - Memory Syncing
    public class func syncLocalMemories() {
        DispatchQueue.global(qos: .background).sync {
            //Retrieve the local memories.
            let memories = MKCoreData.shared.fetchAllMemories()
                        
            for memory in memories {
                //Create a cloud memory instance.
                let cloudMemory = MKCloudMemory(withMKMemory: memory)
                                
                //Create the request.
                guard let jsonData = cloudMemory.jsonRepresentation else { return }
                let request = MKCloudRequest(withOperation: .postMemory, andParameters: [:], andPostData: jsonData)
                if let urlRequest = request.urlRequest {
                    URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                        guard let data = data, let str = String(data: data, encoding: .ascii), error == nil else { return}
                    }.resume()
                }
            }
        }
    }
    
    public class func syncServerMemories() {
        let request = MKCloudRequest(withOperation: .retrieveMemories, andParameters: [:])
        
        guard let urlRequest = request.urlRequest else { return }
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else { return }
            let str = String(data: data, encoding: .utf8)
            let decoder = JSONDecoder()
            do {
                let cloudMemories = try decoder.decode([MKCloudMemory].self, from: data)
                
                for mem in cloudMemories {
                    mem.decrypt()
                }
            }
            catch {
                print(error)
            }
        }.resume()
    }
}
