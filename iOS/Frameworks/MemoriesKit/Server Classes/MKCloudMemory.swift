//
//  MKCloudMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 9/13/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import RNCryptor
import MediaPlayer

class MKCloudMemory: Codable {
    var title: String!
    var description: String!
    var id: String!
    var isDynamic: Bool!
    var songs = [MKCloudSong]()
    
    ///Initializes with an `MKMemory` object and encrypts sensitive data.
    init(withMKMemory memory: MKMemory) {
        
        self.title = memory.title
        self.description = memory.desc
        self.id = memory.storageID.removingAnd
        self.isDynamic = memory.isDynamicMemory

        //Encrypt.
        self.encrypt()
        
        //Items
        guard let items = memory.items else { return }
        
        for item in items {
            let song = MKCloudSong(withMKMemoryItem: item)
            self.songs.append(song)
        }
    }
    
    var jsonRepresentation: Data? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return data
    }
    
    //MARK: - Encryption and Decryption
    private func encrypt() {
        guard let encryptionKey = MKAuth.encryptionKey else { return }
        
        guard let titleData = self.title.data(using: .utf8) else { return }
        let encryptedTitle = RNCryptor.encrypt(data: titleData, withPassword: encryptionKey)
        
        self.title = encryptedTitle.base64EncodedString()
        
        guard let descriptionData = self.description.data(using: .utf8)
            else { return }
        let encryptedDescription = RNCryptor.encrypt(data: descriptionData, withPassword: encryptionKey)
        
        self.description = encryptedDescription.base64EncodedString()
    }
    
    func decrypt() {
        guard let encryptionKey = MKAuth.encryptionKey else { return }
        
        do {
            
            guard let encryptedTitleData = Data(base64Encoded: self.title ?? "", options: .ignoreUnknownCharacters) else { return }
            
            let titleData = try RNCryptor.decrypt(data: encryptedTitleData, withPassword: encryptionKey)
            let title = String(data: titleData, encoding: .utf8)
            self.title = title
            
            
            guard let encryptedDescriptionData = Data(base64Encoded: self.description ?? "", options: .ignoreUnknownCharacters) else { return }
            let descriptionData = try RNCryptor.decrypt(data: encryptedDescriptionData, withPassword: encryptionKey)
            let description = String(data: descriptionData, encoding: .utf8)
            self.description = description
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Local syncing
    /// Syncs the memory with the local data store.
    func sync() {
        var memory: MKMemory!
        if !MKCoreData.shared.contextContains(memoryWithID: self.id ?? "") {
            //Memory not stored locally, create a new `MKMemory` object and save it.
            memory = MKCoreData.shared.createNewMKMemory()
        }
        else {
            memory = MKCoreData.shared.memory(withID: self.id)
        }
        
        memory.isDynamic = NSNumber(booleanLiteral: self.isDynamic)
        memory.title = self.title
        memory.desc = self.description
        memory.storageID = self.id
        
        //Update media item list.
        let songItems = self.songs.map { $0.mpMediaItem }.filter { $0 != nil }.map{ $0! }
        
        //Filter the memory items to delete.
        let memoryItems = memory.items ?? Set()
        let itemsToDelete = memoryItems.filter {
            guard let mediaItem = $0.mpMediaItem else { return false }
            return !songItems.contains(mediaItem)
        }
        
        //Delete the previously deleted memory items and add the new memory items to the memory.
        DispatchQueue.main.async {
            for item in itemsToDelete {
                item.delete()
            }
            
            for item in songItems {
                memory.add(mpMediaItem: item)
            }
        }
        
        
        DispatchQueue.main.async {
            memory.save(sync: false, withAPNS: false)
        }
    }
}

class MKCloudSong: Codable {
    var title: String!
    var album: String!
    var artist: String!
    
    init(withMKMemoryItem memoryItem: MKMemoryItem) {
        self.title = memoryItem.title?.removingAnd.urlEncoded ?? ""
        self.album = memoryItem.albumTitle?.removingAnd.urlEncoded ?? ""
        self.artist = memoryItem.artist?.removingAnd.urlEncoded ?? ""
    }
    
    //MARK: - MPMediaItem
    var mpMediaItem: MPMediaItem? {
        //Create the predicates with the album name and artist name retrieved from the Apple Music Web API.
        let albumTitlePredicate = MPMediaPropertyPredicate(value: self.album, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .contains)
        let albumArtistPredicate = MPMediaPropertyPredicate(value: self.artist, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: .contains)
        let songTitlePredicate = MPMediaPropertyPredicate(value: self.title, forProperty: MPMediaItemPropertyTitle, comparisonType: .equalTo)
        
        
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
}

fileprivate extension String {
    var removingAnd: String {
        return self.replacingOccurrences(of: "&", with: "%26")
    }
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
    
    var base64: String {
        let data = self.data(using: .utf8, allowLossyConversion: false)!
        return data.base64EncodedString()
    }
}
