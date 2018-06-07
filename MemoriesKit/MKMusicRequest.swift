//
//  MKMusicRequest.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 10/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import StoreKit

public class MKMusicRequest {
    //MARK: - Static properties
    ///The base URL for the Apple Music API (user's library).
    private static var baseURLUser = "https://api.music.apple.com/v1/me/"
    
    ///The base URL for the Apple Music API (whole service).
    private static var baseURL = "https://api.music.apple.com/v1/"
    
    ///The URL for retrieving the user's heavy rotation list.
    private static var heavyRotationURL = "\(baseURLUser)history/heavy-rotation"

    ///The URL for retriving the user's recently added list.
    private static var recentlyAddedURL = "\(baseURLUser)recent/played"
    
    ///The URL for retriving top charts.
    private static var topChartsURL = "\(baseURL)catalog/\(MKAuth.cloudServiceStorefrontCountryCode)/charts"
    
    public enum Source {
        case heavyRotation, recentlyPlayed, topCharts
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
    
    ///The generated URLRequest.
    public var urlRequest: URLRequest {
        var request: URLRequest!
        switch source {
        case .heavyRotation? :
            var urlString = "\(MKMusicRequest.heavyRotationURL)?"
            //Add parameters.
            if let offset = offset {
                urlString += "offset=\(offset)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            if let limit = limit {
                urlString += "limit=\(limit)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            //Create the request.
            request = URLRequest(url: URL(string: urlString)!)
            request.addValue(MKAuth.musicUserToken ?? "", forHTTPHeaderField: "Music-User-Token")
        case .recentlyPlayed? :
            var urlString = "\(MKMusicRequest.recentlyAddedURL)?"
            //Add parameters.
            if let offset = offset {
                urlString += "offset=\(offset)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            if let limit = limit {
                urlString += "limit=\(limit)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            //Create the request.
            request = URLRequest(url: URL(string: urlString)!)
            request.addValue(MKAuth.musicUserToken!, forHTTPHeaderField: "Music-User-Token")
        case .topCharts? :
            var urlString = "\(MKMusicRequest.topChartsURL)?types=songs&"
            if let offset = offset {
                urlString += "offset=\(offset)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            if let limit = limit {
                urlString += "limit=\(limit)&".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            if let genre = genre {
                urlString += "genre=\(genre)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            }
            request = URLRequest(url: URL(string: urlString)!)
        default :
            break
        }
        
        request.addValue("Bearer \(MKAuth.developerToken!)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    //MARK: - Initialization
    public init(withSource source: MKMusicRequest.Source, andOffset offset: Int? = nil, andLimit limit: Int? = nil, andGenre genre: String? = nil) {
        //Set properties.
        self.source = source
        self.offset = offset
        self.genre = genre
        self.limit = limit
    }

}
