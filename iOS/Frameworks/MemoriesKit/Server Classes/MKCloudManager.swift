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
}
