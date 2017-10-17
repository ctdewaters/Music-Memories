//
//  MKAppleMusicManager.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import MediaPlayer

public class MKAppleMusicManager {
    
    // MARK: Types
    /// The completion handler that is called when an Apple Music Get User Storefront API call completes.
    typealias GetUserStorefrontCompletionHandler = (_ storefront: String?, _ error: Error?) -> Void
    
    /// The completion handler that is called when an Apple Music Get Recently Played API call completes.
    public typealias RetrievalCompletionHandler = (_ mediaItems: [MPMediaItemCollection?], _ error: Error?) -> Void
    
    // MARK: Properties
    /// The instance of `URLSession` that is going to be used for making network calls.
    lazy var urlSession: URLSession = {
        // Configure the `URLSession` instance that is going to be used for making network calls.
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        return URLSession(configuration: urlSessionConfiguration)
    }()
    
    ///The shared instance.
    public static let shared = MKAppleMusicManager()
    
    //MARK: - Apple Music API Functions

    ///Retrieves the user's recently played albums, with a supplied limit and offset.
    public func retrieveRecentlyPlayed(withLimit limit: Int = 10, andOffset offset: Int = 0, andCompletion completion: @escaping MKAppleMusicManager.RetrievalCompletionHandler) {
        //Ensure we have developer and user tokens.
        if MKAuth.developerToken == nil {
            fatalError("FATAL ERROR: Developer token not retrieved.")
        }
        if MKAuth.musicUserToken == nil {
            fatalError("FATAL ERROR: Music user token not retrieved.")
        }
    
        //Create the request.
        let request = MKMusicRequest(withSource: .recentlyPlayed, andOffset: offset, andLimit: limit, andGenre: nil)
        
        //Run the request.
        urlSession.dataTask(with: request.urlRequest) { (data, response, error) in
            //Check for error and correct response status code.
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                completion([], error)
                return
            }
            
            do {
                //Retrieve JSON object and it's results data.
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any], let results = json[ResponseRootJSONKeys.data] as? [[String: Any]] else {
                    throw SerializationError.missing(ResponseRootJSONKeys.data)
                }
                //Convert json to MKMediaItem, and run the completion block.
                let retrievedItems = try self.processMediaItems(from: results)
                let albumCollections = retrievedItems.map {
                    return $0.albumCollection()
                }
                completion(albumCollections, nil)
            }
            catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    ///Retrieves the user's heavy rotation collection, with a supplied limit and offset.
    public func retrieveHeavyRotation(withLimit limit: Int = 10, andOffset offset: Int = 0, andCompletion completion: @escaping MKAppleMusicManager.RetrievalCompletionHandler) {
        //Ensure we have developer and user tokens.
        if MKAuth.developerToken == nil {
            fatalError("FATAL ERROR: Developer token not retrieved.")
        }
        if MKAuth.musicUserToken == nil {
            fatalError("FATAL ERROR: Music user token not retrieved.")
        }
        
        //Create the request.
        let request = MKMusicRequest(withSource: .heavyRotation, andOffset: offset, andLimit: limit, andGenre: nil)
        
        //Run the request.
        urlSession.dataTask(with: request.urlRequest) { (data, response, error) in
            //Check for error and correct response status code.
            guard error == nil, let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 200 else {
                completion([], error)
                return
            }
            
            do {
                //Retrieve JSON object and it's results data.
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any], let results = json[ResponseRootJSONKeys.data] as? [[String: Any]] else {
                    throw SerializationError.missing(ResponseRootJSONKeys.data)
                }
                //Convert json to MKMediaItem, and run the completion block.
                let retrievedItems = try self.processMediaItems(from: results)
                let albumCollections = retrievedItems.map {
                    return $0.albumCollection()
                }
                completion(albumCollections, nil)
            }
            catch {
                fatalError("An error occurred: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    //Processes song media items.
    func processMediaItems(from json: [[String: Any]]) throws -> [MKMediaItem] {
        let songMediaItems = try json.map { try MKMediaItem(json: $0) }
        return songMediaItems
    }
}


public extension MPMediaItemCollection {
    ///The items in the collection, sorted by play count.
    public var playCountSortedItems: [MPMediaItem] {
        let sortedItems = self.items.sorted {
            return $0.playCount > $1.playCount
        }
        return sortedItems
    }
}
