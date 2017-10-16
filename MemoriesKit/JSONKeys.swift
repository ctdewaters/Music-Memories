//
//  JSONKeys.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation

/// Keys related to the `Response Root` JSON object in the Apple Music API.
struct ResponseRootJSONKeys {
    static let data = "data"
    
    static let results = "results"
    
    static let next = "next"
}

/// Keys related to the `Resource` JSON object in the Apple Music API.
struct ResourceJSONKeys {
    static let identifier = "id"
    
    static let attributes = "attributes"
    
    static let type = "type"
}

/// The various keys needed for parsing a JSON response from the Apple Music Web Service.
struct ResourceTypeJSONKeys {
    static let songs = "songs"
    
    static let albums = "albums"
    
    
}

