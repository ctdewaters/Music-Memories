//
//  MKAppleMusicManager.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

#if os(iOS)
import Foundation
import MediaPlayer

@available(iOS 11.0, *)
///`MKAppleMusicManager`: Handles requests to the Apple Music web API.
public class MKAppleMusicManager {
    
    // MARK: Types
    /// The completion handler that is called when an Apple Music Get User Storefront API call completes.
    typealias GetUserStorefrontCompletionHandler = (_ storefront: String?, _ error: Error?) -> Void
    
    /// The completion handler that is called when an Apple Music  API call completes.
    public typealias RetrievalCompletionHandler = (_ mediaItems: [MKMediaItem]?, _ error: Error?, _ httpStatusCode: Int) -> Void
    
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
    
    /// Runs a request to the Apple Music API with a given source.
    /// - Parameter source: The source in the Apple Music API to retrieve data from.
    /// - Parameter limit: The request limit.
    /// - Parameter offset: The request offset.
    /// - Parameter searchTerm: The search term for the request (for search requests only.
    public func run(requestWithSource source: MKAppleMusicRequest.Source, limit: Int = 10, offset: Int = 0, searchTerm: String? = nil, andCompletion completion: @escaping MKAppleMusicManager.RetrievalCompletionHandler) {
        //Ensure we have developer and music user tokens.
        if MKAuth.developerToken == nil {
            print("FATAL ERROR: Developer token not retrieved.")
        }
        if MKAuth.musicUserToken == nil {
            print("FATAL ERROR: Music user token not retrieved.")
        }
        
        //Create an `MKAppleMusicRequest`.
        let request = MKAppleMusicRequest(withSource: source, andOffset: offset, andLimit: limit, searchTerm: searchTerm, andGenre: nil)
        
        //Run the URLSession data task.
        urlSession.dataTask(with: request.urlRequest) { (data, response, error) in
            
            //Check for error, and correct HTTP response code.
            guard error == nil, let urlResponse = response as? HTTPURLResponse else {
                completion([], error, -1)
                return
            }
            if urlResponse.statusCode != 200 {
                completion([], error, urlResponse.statusCode)
                return
            }
            
            do {
                let string = String(data: data!, encoding: .ascii)
                                
                //Retrieve JSON object and it's results data.
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String: Any] else {
                    return
                }
                
                var results = [[String: Any]]()
                
                if source.isLibrary {
                    //Handle library response.
                    if let resultsData = json[ResponseRootJSONKeys.results] as? [String: Any], let songsData = resultsData[ResponseLibraryJSONKeys.songs] as? [String: Any], let songsDataFinal = songsData[ResponseRootJSONKeys.data] as? [[String: Any]]{
                        results = songsDataFinal
                    }
                }
                else {
                    guard let resultsData = json[ResponseRootJSONKeys.data] as? [[String: Any]] else {
                        throw SerializationError.missing(ResponseRootJSONKeys.data)
                    }
                    results = resultsData
                }
                                
                //Convert json to MKMediaItem, and run the completion block.
                let retrievedItems = try self.processMediaItems(from: results)
                completion(retrievedItems, nil, urlResponse.statusCode)
            }
            catch {
                print("An error occurred: \(error.localizedDescription)")
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
#endif
