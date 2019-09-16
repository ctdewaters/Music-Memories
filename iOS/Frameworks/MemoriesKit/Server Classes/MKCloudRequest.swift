//
//  MKCloudRequest.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 9/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

/// `MKCloudRequest`: Represents a request to the Music Memories server.
public class MKCloudRequest {
    
    //MARK: - URLs
    static let apiURL = "https://www.musicmemories.app/api/"
    static let authURL = "\(apiURL)auth/"
    static let userURL = "\(apiURL)user/"
    static let apnsURL = "\(apiURL)apns/"
    
    ///`MKCloudRequest.Operation`: The request operation to send to the Music Memories server.
    public enum Operation {
        case postMemory, deleteMemory, retrieveMemories, registerAPNSToken, authenticate, retrieveDeletedMemories, restoreMemory
        
        var urlString: String {
            switch self {
            case .postMemory :
                return "\(MKCloudRequest.userURL)postMemory.php"
            case .deleteMemory :
                return "\(MKCloudRequest.userURL)deleteMemory.php"
            case .retrieveMemories :
                return "\(MKCloudRequest.userURL)retrieveMemories.php"
            case .retrieveDeletedMemories :
                return "\(MKCloudRequest.userURL)retrieveDeletedMemories.php"
            case .registerAPNSToken :
                return "\(MKCloudRequest.apnsURL)registerDeviceToken.php"
            case .authenticate:
                return "\(MKCloudRequest.authURL)register.php"
            case .restoreMemory:
                return "\(MKCloudRequest.userURL)restoreDeletedMemory.php"
            }
        }
    }
    
    var operation: Operation?
    
    //MARK: - Parameter properties
    
    ///The authentication parameters, containing the API token, the user's Sign in with Apple ID, and auth token.
    var authenticationParameters: [String: String]? {
        guard let userAuthToken = MKAuth.userAuthToken, let userID = MKAuth.userID else { return nil }
        
        return ["apiKey" : "F610FHRMJTPL9NH1XPYFQDYRYSXCX9XA", "appleID" : userID, "password" : userAuthToken]
    }
    
    ///Any additional parameters for the request.
    var parameters = [String : String]()
    
    var postData: Data?
    
    
    //MARK: - Initialization
    init(withOperation operation: Operation, andParameters parameters: [String : String], andPostData postData: Data? = nil) {
        self.operation = operation
        self.parameters = parameters
        self.postData = postData
    }
    
    //MARK: - URLRequest Creation
    var urlRequest: URLRequest? {
        guard let operation = self.operation else { return nil }
        var urlString = "\(operation.urlString)?"
        
        guard let authenticationParameters = self.authenticationParameters else { return nil }
        urlString += self.parameterDictionaryToString(authenticationParameters)
        urlString += self.parameterDictionaryToString(self.parameters)
        
        if operation == .postMemory {
            guard let postData = self.postData else { return nil }
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            var requestBodyData = "payload=".data(using: .utf8)!
            requestBodyData.append(postData)
            request.httpBody = requestBodyData
            
            return request
        }
                
        return URLRequest(url: URL(string: urlString)!)
    }
    
    //MARK: - Parameter String Creation
    func parameterDictionaryToString(_ parameters: [String : String]) -> String {
        var string = ""
        for key in parameters.keys {
            if let value = parameters[key] {
                string += "\(key)=\(value)&".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            }
        }
        return string
    }
}
