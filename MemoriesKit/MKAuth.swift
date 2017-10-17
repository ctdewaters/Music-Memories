//
//  MKAuth.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 10/15/17.
//  Copyright © 2017 Near Future Marketing. All rights reserved.
//

import Foundation
import StoreKit
import DAKeychain

///MKAuth class: Handles user and developer authentication with Apple Music.
public class MKAuth {
    
    ///MARK: - Static properties.
    ///The base url to the music memories web service.
    private static let baseURL = "https://www.bounceee.com/musicMemories/scripts/"
    ///The url for retriveing the developer token.
    private static let developerTokenURL: URL? = URL(string: "\(baseURL)retrieveDeveloperToken.php")
    
    ///The developer token, if it has already been retrieved.
    public static var developerToken: String?
    
    ///The instance of `SKCloudServiceController` that will be used for querying the available `SKCloudServiceCapability` and Storefront Identifier.
    public static let cloudServiceController = SKCloudServiceController()
    
    ///The current set of capabilites that we can currently use.
    public static var cloudServiceCapabilities = SKCloudServiceCapability()
    
    ///The current two letter country code associated with the currently authenticated iTunes Store account.
    public static var cloudServiceStorefrontCountryCode = "US"
    
    ///The current authenticated iTunes Store account's music user token.
    public static var musicUserToken: String? {
        return DAKeychain.shared["musicUserToken"]
    }
    
    //MARK: - Notification names
    public static let developerTokenWasRetrievedNotification = Notification.Name("developerTokenWasRetreivedNotification")
    public static let musicUserTokenWasRetrievedNotification = Notification.Name("musicUserTokenWasRetrievedNotification")
    
    
    //MARK: - Token Retrieval
    ///Retrieves the developer token for interaction with the Apple Music servers, located on the Music Memories web service.
    public class func retrieveDeveloperToken(withCompletion completion: @escaping (String?) -> Void) {
        //Check if we have already retrieved the developer token.
        if let developerToken = MKAuth.developerToken {
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
            MKAuth.developerToken = string
            NotificationCenter.default.post(name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
            completion(string)
        }).resume()
    }
    
    ///Retrieves the music user token for interaction with a user's library in Apple Music.
    public class func retrieveMusicUserToken(withCompletion completion: ((String?) -> Void)? = nil) {
        if SKCloudServiceController.authorizationStatus() == .authorized {
            if let musicUserToken = self.musicUserToken {
                //Music user token already generated, retrieve the developer token from the server and run the completion block.
                MKAuth.retrieveDeveloperToken { devToken in
                    NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
                    completion?(musicUserToken)
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
                        print(error)
                        completion?(nil)
                        return
                    }
                    //Store the music user token, and run the completion block.
                    DAKeychain.shared["musicUserToken"] = userToken
                    NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
                    completion?(userToken)
                })
                
            }
        }
        else if SKCloudServiceController.authorizationStatus() == SKCloudServiceAuthorizationStatus.notDetermined {
            MKAuth.requestCloudServiceAuthorization {
                authorized in
                MKAuth.retrieveMusicUserToken(withCompletion: completion)
            }
        }
    }
    
    
    //MARK: - SKCloudServiceController permission requests.
    ///Requests user for permssion to use cloud services.
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
    
    ///Requests the service capabilites we can use.
    class func requestCloudServiceCapabilities(withCompletion completion: @escaping ()->Void) {
        cloudServiceController.requestCapabilities(completionHandler: { (cloudServiceCapability, error) in
            guard error == nil else {
                fatalError("An error occurred when requesting capabilities: \(error!.localizedDescription)")
            }
            
            MKAuth.cloudServiceCapabilities = cloudServiceCapability
            
            completion()
        })
    }
    
//    func requestStorefrontCountryCode() {
//        let completionHandler: (String?, Error?) -> Void = { [weak self] (countryCode, error) in
//            guard error == nil else {
//                print("An error occurred when requesting storefront country code: \(error!.localizedDescription)")
//                return
//            }
//
//            guard let countryCode = countryCode else {
//                print("Unexpected value from SKCloudServiceController for storefront country code.")
//                return
//            }
//
//            self.cloudServiceStorefrontCountryCode = countryCode
//
//            NotificationCenter.default.post(name: AuthorizationManager.cloudServiceDidUpdateNotification, object: nil)
//        }
//
//        if SKCloudServiceController.authorizationStatus() == .authorized {
//            if #available(iOS 11.0, *) {
//                /*
//                 On iOS 11.0 or later, if the `SKCloudServiceController.authorizationStatus()` is `.authorized` then you can request the storefront
//                 country code.
//                 */
//                MKAuth.cloudServiceController.requestStorefrontCountryCode(completionHandler: completionHandler)
//            } else {
//                appleMusicManager.performAppleMusicGetUserStorefront(userToken: userToken, completion: completionHandler)
//            }
//        } else {
//            determineRegionWithDeviceLocale(completion: completionHandler)
//        }
//    }
}

//URLSession object for interaction with the MusicMemories and MusicKit Server
var urlSession: URLSession = {
    let config = URLSessionConfiguration.default
    return URLSession(configuration: config)
}()
