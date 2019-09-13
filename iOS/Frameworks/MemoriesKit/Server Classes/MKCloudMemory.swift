//
//  MKCloudMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 9/13/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

class MKCloudMemory: Codable {
    var title: String!
    var description: String!
    var id: String!
    var isDynamic: Bool!
    var songs = [MKCloudSong]()
    
    init(withMKMemory memory: MKMemory) {
        self.title = memory.title?.removingAnd.urlEncoded
        self.description = memory.desc?.removingAnd.urlEncoded
        self.id = memory.storageID.removingAnd
        self.isDynamic = memory.isDynamicMemory
        
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
}

fileprivate extension String {
    var removingAnd: String {
        return self.replacingOccurrences(of: "&", with: "%26")
    }
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
