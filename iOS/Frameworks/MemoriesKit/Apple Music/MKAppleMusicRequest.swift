//
//  MKMusicRequest.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 10/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation

import StoreKit

///`MKMusicRequest`: Represents a request to the Apple Music web API.
public class MKAppleMusicRequest {
    //MARK: - Static properties
    ///The base URL for the Apple Music API (user's library).
    private static var baseURLUser = "https://api.music.apple.com/v1/me/"
    
    ///The base URL for the Apple Music API (whole service).
    private static var baseURL = "https://api.music.apple.com/v1/"
    
    ///The URL for retrieving the user's heavy rotation list.
    private static var heavyRotationURL = "\(baseURLUser)history/heavy-rotation"

    ///The URL for retriving the user's recently played  list.
    private static var recentlyPlayedURL = "\(baseURLUser)recent/played"
    
    ///The URL for the user's music library.
    private static var libraryURL = "\(baseURLUser)library/"
    
    ///The URL for searching the user's music library.
    private static var librarySearchURL = "\(libraryURL)search"
    
    ///The URL for fetching songs in the user's music library.
    private static var fetchLibrarySongsURL = "\(libraryURL)songs"
    
    ///The URL for retriving top charts.
    private static var topChartsURL = "\(baseURL)catalog/\(MKAuth.cloudServiceStorefrontCountryCode)/charts"
    
    ///The URL for retriving catalog information for a song.
    private static var songCatalogURL = "\(baseURL)catalog/\(MKAuth.cloudServiceStorefrontCountryCode)/songs"
    
    public enum Source {
        case heavyRotation, recentlyPlayed, recentlyAdded, topCharts, librarySearch, libraryFetchSongs, catalogFetchSong
        
        var isLibrary: Bool {
            if self == .librarySearch {
                return true
            }
            return false
        }
    }
    
    //MARK: - Properties
    ///The source of songs to retrieve.
    var source: Source!
    
    ///The offset of the request, if specified.
    var offset: Int?
    
    ///The limit of the request, if specified.
    var limit: Int?
    
    ///The genre to use (chart request only).
    public var genre: String?
    
    ///The search term (only used for search queries).
    var searchTerm: String?
    
    ///The song IDs to fetch (for song fetch requests only).
    var songIDs: [String]?
    
    ///The generated URLRequest.
    public var urlRequest: URLRequest {
        var request: URLRequest!
        switch source {
        case .heavyRotation? :
            //Create the request.
            request = self.createURLRequest(withBaseURLString: MKAppleMusicRequest.heavyRotationURL, offset: offset, limit: limit)
        case .recentlyPlayed? :
            //Create the request.
            request = self.createURLRequest(withBaseURLString: MKAppleMusicRequest.recentlyPlayedURL, offset: offset, limit: limit)
        case .topCharts? :
            //Setup parameters with a genre (if specified).
            var parameters = [String: String]()
            if let genre = genre {
                parameters["genre"] = genre
            }
            //Create the request.
            request = self.createURLRequest(withBaseURLString: MKAppleMusicRequest.topChartsURL, offset: offset, limit: limit, andParameters: parameters)
        case .librarySearch:
            //Setup parameters with the search term.
            var parameters = [String: String]()
            if let searchTerm = searchTerm {
                parameters["term"] = searchTerm
                parameters["types"] = "library-songs"
            }
            //Create the request.
            request = self.createURLRequest(withBaseURLString: MKAppleMusicRequest.librarySearchURL, offset: offset, limit: limit, andParameters: parameters)
            
        case .libraryFetchSongs :
            var parameters = [String: String]()
            if let songIDs = self.songIDs {
                parameters["ids"] = songIDs.implodedString
            }
            //Create the request.
            request = self.createURLRequest(withBaseURLString: MKAppleMusicRequest.fetchLibrarySongsURL, offset: nil, limit: nil, andParameters: parameters)
            
        case .catalogFetchSong :
            var parameters = [String: String]()
            var urlString = ""
            if let songID = self.songIDs?.first {
                urlString = "\(MKAppleMusicRequest.songCatalogURL)/\(songID)"
            }
            request = self.createURLRequest(withBaseURLString: urlString, offset: nil, limit: nil, andParameters: nil)
        default :
            break
        }
        request.addValue("Bearer \(MKAuth.developerToken ?? "")", forHTTPHeaderField: "Authorization")
        request.addValue(MKAuth.musicUserToken ?? "", forHTTPHeaderField: "Music-User-Token")
        return request
    }
    
    //MARK: - Initialization
    public init(withSource source: MKAppleMusicRequest.Source, andOffset offset: Int? = nil, andLimit limit: Int? = nil, searchTerm: String? = nil, songIDs: [String]? = nil, andGenre genre: String? = nil) {
        //Set properties.
        self.source = source
        self.offset = offset
        self.genre = genre
        self.limit = limit
        self.searchTerm = searchTerm?.replacingOccurrences(of: " ", with: "+")
        self.songIDs = songIDs
    }
    
    //MARK: - URLRequest Creation
    fileprivate func createURLRequest(withBaseURLString baseURLString: String, offset: Int?, limit: Int?, andParameters param: [String: String]? = nil) -> URLRequest {
        
        var baseURLString = "\(baseURLString)?"
        
        //Add limit and offset to the URL.
        if let offset = offset {
            baseURLString += "offset=\(offset)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        if let limit = limit {
            baseURLString += "limit=\(limit)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        }
        
        //Add any more parameters, if any.
        if let param = param {
            for key in param.keys {
                if let value = param[key] {
                    baseURLString += "\(key)=\(value)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                }
            }
        }
        baseURLString.removeLast()
        print(baseURLString)
        
        return URLRequest(url: URL(string: baseURLString)!)
    }
}

extension Array {
    var implodedString: String {
        var string = ""
        for i in self {
            string += "\(i),"
        }
        string.removeLast()
        return string
    }
}
