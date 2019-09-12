//
//  MKMediaItem.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import MediaPlayer

///`MKMediaItem`: Represents a resource object in the Apple Music Web Service.
public class MKMediaItem: TextOutputStreamable {

    // MARK: Types
    
    /// The type of resource.
    public enum MediaType: String {
        case songs, albums, stations, playlists, librarysongs = "library-songs"
    }
    
    /// The various keys needed for serializing an instance of `MKMediaItem` using a JSON response from the Apple Music Web Service.
    struct JSONKeys {
        static let identifier = "id"
        
        static let type = "type"
        
        static let attributes = "attributes"
        
        static let name = "name"
        
        static let artistName = "artistName"
        
        static let artwork = "artwork"
        
        static let url = "url"
    }
    
    // MARK: Properties
    /// The persistent identifier of the resource which is used to add the item to the playlist or trigger playback.
    public let identifier: String
    
    /// The localized name of the album or song.
    public let name: String
    
    /// The artist’s name.
    public let artistName: String
    
    /// The album artwork associated with the song or album.
    public let artwork: MKMediaItemArtwork
    
    /// The type of the MediaType of this item.
    public let type: MediaType
    
    public var url: URL?
    
    // MARK: Initialization
    public init(json: [String: Any]) throws {
                
        guard let identifier = json[JSONKeys.identifier] as? String else {
            throw SerializationError.missing(JSONKeys.identifier)
        }
        
        guard let typeString = json[JSONKeys.type] as? String, let type = MediaType(rawValue: typeString) else {
            throw SerializationError.missing(JSONKeys.type)
        }
        
        guard let attributes = json[JSONKeys.attributes] as? [String: Any] else {
            throw SerializationError.missing(JSONKeys.attributes)
        }
        
        guard let name = attributes[JSONKeys.name] as? String else {
            throw SerializationError.missing(JSONKeys.name)
        }
        
        var artistName = String()
        if type != .stations && type != .playlists {
            guard let artist = attributes[JSONKeys.artistName] as? String else {
                throw SerializationError.missing(JSONKeys.artistName)
            }
            artistName = artist
        }
        
        guard let artworkJSON = attributes[JSONKeys.artwork] as? [String: Any], let artwork = try? MKMediaItemArtwork(json: artworkJSON) else {
            throw SerializationError.missing(JSONKeys.artwork)
        }
        
        self.identifier = identifier
        self.type = type
        self.name = name
        self.artistName = artistName
        self.artwork = artwork
        
        if let urlString = attributes[JSONKeys.url] as? String {
            self.url = URL(string: urlString)
        }
    }
    
    //MARK: - MediaPlayer functions
    ///Retrieves an album from the MediaPlayer library using a MKMediaItem's metadata.
    public var albumCollection: MPMediaItemCollection? {
        
        if self.type != .albums {
            return nil
        }
        
        //Create the predicates with the album name and artist name retrieved from the Apple Music Web API.
        let albumTitlePredicate = MPMediaPropertyPredicate(value: self.name, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .contains)
        let albumArtistPredicate = MPMediaPropertyPredicate(value: self.artistName, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: .contains)
        //Create the query object, and add the predicates
        let albumQuery = MPMediaQuery.albums()
        albumQuery.addFilterPredicate(albumTitlePredicate)
        albumQuery.addFilterPredicate(albumArtistPredicate)
        
        var album: MPMediaItemCollection?
        //Retrieve the collections from the query.
        if let collections = albumQuery.collections {
            if collections.count > 0 {
                album = collections[0]
            }
        }
        
        return album
    }
    
    ///Retrieves a Media Item from the MediaPlayer library using MKMediaItem's metadata.
    public var mpMediaItem: MPMediaItem? {
        if self.type != .songs {
            return nil
        }
        
        //Create the predicates with the album name and artist name retrieved from the Apple Music Web API.
        let albumTitlePredicate = MPMediaPropertyPredicate(value: self.name, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .contains)
        let albumArtistPredicate = MPMediaPropertyPredicate(value: self.artistName, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: .contains)
        let songTitlePredicate = MPMediaPropertyPredicate(value: self.name, forProperty: MPMediaItemPropertyTitle, comparisonType: .equalTo)
        
        
        //Create the query object, and add the predicates
        let songsQuery = MPMediaQuery.songs()
        songsQuery.addFilterPredicate(albumTitlePredicate)
        songsQuery.addFilterPredicate(albumArtistPredicate)
        songsQuery.addFilterPredicate(songTitlePredicate)
        
        var song: MPMediaItem?
        //Retrieve the collections from the query.
        if let items = songsQuery.items {
            song = items.first
        }

        return song
    }

    //MARK: - TextOutputStreamable
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        target.write("MKMediaItem [ \n\t ID: \(self.identifier) \n\t Name: \(self.name) \n\t Artist Name: \(self.artistName) \n\t Artwork URL: \(self.artwork.imageURL(size: CGSize(width: 500, height: 500))) \n\t Media Type: \(self.type) \n]")
    }

}

///Represents a Serialization Error that occurred when parsing JSON.
public enum SerializationError: Error {
    
    /// This case indicates that the expected field in the JSON object is not found.
    case missing(String)
}

