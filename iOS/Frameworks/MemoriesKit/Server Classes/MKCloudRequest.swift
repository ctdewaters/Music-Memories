//
//  MKCloudRequest.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 9/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

/// `MKCloudRequest`: Represents a request to the Music Memories server.
class MKCloudRequest {
    
    //MARK: - URLs
    static let apiURL = "https://www.musicmemories.app/api/development/"
    static let authURL = "\(apiURL)auth/"
    static let userURL = "\(apiURL)user/"
    static let apnsURL = "\(apiURL)apns/"
    static let memoryImageURL = "https://www.musicmemories.app/memories/images/"
    
    ///`MKCloudRequest.Operation`: The request operation to send to the Music Memories server.
    public enum Operation {
        case postMemory, deleteMemory, retrieveMemories, registerAPNSToken, authenticate, retrieveDeletedMemories, restoreMemory, uploadImage, deleteImage, retrieveImages, deleteSong
        
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
            case .uploadImage :
                return "\(MKCloudRequest.userURL)uploadImage.php"
            case .deleteImage :
                return "\(MKCloudRequest.userURL)deleteImage.php"
            case .retrieveImages :
                return "\(MKCloudRequest.userURL)retrieveImages.php"
            case .deleteSong :
                return "\(MKCloudRequest.userURL)deleteSong.php"
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
    
    var filename: String?
    
    //MARK: - Initialization
    init(withOperation operation: Operation, andParameters parameters: [String : String], andPostData postData: Data? = nil, withFileName filename: String? = nil) {
        self.operation = operation
        self.parameters = parameters
        self.postData = postData
        self.filename = filename
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
        
        else if operation == .uploadImage {
            guard let postData = self.postData, let filename = self.filename else { return nil }
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundaryStr = self.generateBoundaryString()
            request.setValue("multipart/form-data; boundary=\(boundaryStr)", forHTTPHeaderField: "Content-Type")
            request.httpBody = self.createFileUploadBody(filename: filename, data: postData, boundary: boundaryStr)
            
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
    
    //MARK: - File Uploading
    
    private func createFileUploadBody(withParameters parameters: [String: String]? = nil, filename: String, data: Data, boundary: String) -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append(string: "--\(boundary)\r\n")
                body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append(string: "\(value)\r\n")
            }
        }
       
        let mimetype = "application/octet-stream"
                
        body.append(string: "--\(boundary)\r\n")
        body.append(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(data)
        body.append(string: "\r\n")
        
        body.append(string: "--\(boundary)--\r\n")
        
        return body
    }

    
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

fileprivate extension Data {
    mutating func append(string: String) {
        if let data = string.data(using: .utf8, allowLossyConversion: true) {
            self.append(data)
        }
    }
}
