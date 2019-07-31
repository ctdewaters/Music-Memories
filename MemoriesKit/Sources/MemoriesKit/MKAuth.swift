//
//  MKAuth.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 10/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation

#if os(iOS)
import StoreKit

@available(iOS 11.0, *)
/// `MKAuth`: Handles authentication with Apple Music.
public class MKAuth {
    //MARK: - Static Properties
    ///The base URL to the MemoriesKit web API.
    private static let baseURL = "https://www.collindewaters.com/musicmemories/"
    
    ///Developer token URL.
    private static let developerTokenURL: URL? = URL(string: "\(baseURL)retrieveDeveloperToken.php")
    
    ///User defaults.
    private static let userDefaults = UserDefaults.standard
    
    ///The developer token, if it has already been retrieved.
    public static var developerToken: String? {
        set {
            MKAuth.userDefaults.set(newValue, forKey: "developerToken")
        }
        get {
            return MKAuth.userDefaults.string(forKey: "developerToken")
        }
    }
    
    ///The instance of `SKCloudServiceController` used for querying the available `SKCloudServiceCapability` and Storefront Identifier.
    public static let cloudServiceController = SKCloudServiceController()
    
    ///The current set of capabilites that we can currently use.
    public static var cloudServiceCapabilities = SKCloudServiceCapability()
    
    ///The current two letter country code associated with the currently authenticated iTunes Store account.
    public static var cloudServiceStorefrontCountryCode = "US"
    
    ///The current authenticated iTunes Store account's music user token.
    public static var musicUserToken: String? {
        set {
            MKAuth.userDefaults.set(newValue, forKey: "musicUserToken")
        }
        get {
            return MKAuth.userDefaults.string(forKey: "musicUserToken")
        }
    }
    
    ///If true, user is an Apple Music subscriber.
    public static var isAppleMusicSubscriber: Bool {
        if MKAuth.cloudServiceCapabilities.contains(.musicCatalogPlayback)  {
            return true
        }
        return false
    }
    
    ///If true, user is eligible to become an Apple Music subscriber.
    public static var canBecomeAppleMusicSubscriber: Bool {
        if MKAuth.cloudServiceCapabilities.contains(.musicCatalogSubscriptionEligible) {
            return true
        }
        return false
    }
    
    ///If true, the user has allowed access to their music library.
    public static var allowedLibraryAccess: Bool {
        if SKCloudServiceController.authorizationStatus() == .authorized {
            return true
        }
        return false
    }
    
    ///If true, the music user token has been attempted to be retrieved once.
    public static var musicUserTokenRetrievalAttempts = 0
    
    //MARK: - Notification Names
    
    ///Notification run when developer token has been successfully retrieved.
    public static let developerTokenWasRetrievedNotification = Notification.Name("developerTokenWasRetreivedNotification")
    
    ///Notification run when Music User Token has been successfully retrieved.
    public static let musicUserTokenWasRetrievedNotification = Notification.Name("musicUserTokenWasRetrievedNotification")
    
    //MARK: - Token Retrieval
    
    /// Retrieves the developer token for interaction with the Apple Music servers, located on the Music Memories web service.
    /// - Parameter completion: A completion handler that will run once the request has been completed.
    public class func retrieveDeveloperToken(withCompletion completion: @escaping (String?) -> Void) {
        //Check if we have already retrieved the developer token.
        if let developerToken = MKAuth.developerToken {
            print(developerToken)
            //Token retrieved, run completion.
            completion(developerToken)
            return
        }
        
        //Check if developer token url is valid.
        guard let developerTokenURL = MKAuth.developerTokenURL else {
            completion(nil)
            return
        }
        //URL valid, run request.
        urlSession.dataTask(with: developerTokenURL, completionHandler: { (data, response, error) in
            //Check if data was received.
            guard let data = data else {
                completion(nil)
                return
            }
            //Data received, convert to string and run the completion block.
            let string = String(data: data, encoding: .ascii)
            
            //Set the developer token value in MKAuth.
            MKAuth.developerToken = string
            NotificationCenter.default.post(name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
            completion(string)
        }).resume()
    }
    
    /// Retrieves the music user token for interaction with a user's library in Apple Music.
    /// - Parameter completion: A completion handler that will run once the request has been completed.
    public class func retrieveMusicUserToken(withCompletion completion: ((String?) -> Void)? = nil) {
        MKAuth.musicUserTokenRetrievalAttempts += 1
        
        if SKCloudServiceController.authorizationStatus() == .authorized {
            if let musicUserToken = self.musicUserToken {
                print(musicUserToken)
                MKAuth.requestCloudServiceCapabilities {
                    //Music user token already generated, retrieve the developer token from the server and run the completion block.
                    MKAuth.retrieveDeveloperToken { devToken in
                        
                        NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
                        completion?(musicUserToken)
                    }
                }
                return
            }
            
            //Retrieve the developer token.
            MKAuth.retrieveDeveloperToken { developerToken in
                guard let devToken = developerToken else {
                    //Developer token invalid.
                    completion?(nil)
                    return
                }

                //Retrieve the music user token.
                SKCloudServiceController().requestUserToken(forDeveloperToken: devToken, completionHandler: { (userToken, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        completion?(nil)
                        return
                    }
                    //Store the music user token, and run the completion block.
                    MKAuth.musicUserToken = userToken
                    NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
                    completion?(userToken)
                })
                
            }
        }
        else if SKCloudServiceController.authorizationStatus() == SKCloudServiceAuthorizationStatus.notDetermined {
            MKAuth.requestCloudServiceAuthorization {
                authorized in
                
                //Check if the user authorized.
                if authorized {
                    //Authorized, attempt to retrieve the music user token if no attempt has been made.
                    if MKAuth.musicUserTokenRetrievalAttempts <= 2 {
                        MKAuth.retrieveMusicUserToken(withCompletion: completion)
                    }
                    else {
                        completion?(nil)
                    }
                }
                else {
                    completion?(nil)
                }
            }
        }
        else {
            //Denied.
            completion?(nil)
        }
    }
    
    //MARK: - Token Testing and Resetting
    
    /// Tests the retrieved music user and developer tokens for validity (completion block returns true if successful).
    /// - Parameter completion: A callback, which will be run with true if the tokens are valid.
    public class func testTokens(completion: @escaping (Bool) -> Void) {
        if MKAuth.musicUserToken != nil, MKAuth.developerToken != nil {
            MKAppleMusicManager.shared.run(requestWithSource: .heavyRotation) { (mkMediaItems, error, statusCode) in
                var valid = true
                if statusCode != 200 {
                    //Tokens invalid.
                    valid = false
                }
                
                //Run completion block.
                completion(valid)
            }
        }
        else {
            completion(false)
        }
    }
    
    ///Resets the Music User Token and Developer Token.
    public class func resetTokens() {
        MKAuth.developerToken = nil
        MKAuth.musicUserToken = nil
    }
    
    //MARK: - SKCloudServiceController Permission Requests
    
    /// Requests user for permssion to use cloud services.
    /// - Parameter completion: Callback run after completion.
    public class func requestCloudServiceAuthorization(withCompletion completion: @escaping (Bool) -> Void) {
        guard SKCloudServiceController.authorizationStatus() == .notDetermined else {
            if SKCloudServiceController.authorizationStatus() == .authorized {
                completion(true)
                return
            }
            completion(false)
            return
        }
        
        //Prompt user for permission.
        SKCloudServiceController.requestAuthorization { (authorizationStatus) in
            switch authorizationStatus {
            case .authorized:
                self.requestCloudServiceCapabilities {
                    completion(true)
                }
            default:
                completion(false)
                break
            }
        }
    }
    
    /// Requests the service capabilites we can use.
    /// - Parameter completion: Callback run after completion.
    public class func requestCloudServiceCapabilities(withCompletion completion: @escaping ()->Void) {
        cloudServiceController.requestCapabilities(completionHandler: { (cloudServiceCapability, error) in
            guard error == nil else {
                print("An error occurred when requesting capabilities: \(error!.localizedDescription)")
                return
            }
            
            MKAuth.cloudServiceCapabilities = cloudServiceCapability
            
            completion()
        })
    }
}

///URLSession object for interaction with the MemoriesKit and MusicKit Server
var urlSession: URLSession = {
    let config = URLSessionConfiguration.default
    return URLSession(configuration: config)
}()

#endif
