//
//  MPMediaItemExtensions.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/9/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

extension MPMediaQuery {
    class func retrieveItemsAdded(betweenDates startDate: Date, and endDate: Date) -> [MPMediaItem] {
        let query = MPMediaQuery.songs()
        
        if let items = query.items {
            let filteredItems = items.filter {
                return ($0.dateAdded.compare(startDate) == .orderedDescending) && ($0.dateAdded.compare(endDate) == .orderedAscending)
            }
            return filteredItems.sorted {
                return $0.dateAdded < $1.dateAdded
            }
        }
        return []
    }
    
    class func retrieveItemsReleased(betweenDates startDate: Date, and endDate: Date) -> [MPMediaItem] {
        let query = MPMediaQuery.songs()
        
        if let items = query.items {
            let filteredItems = items.filter {
                guard let releaseDate = $0.releaseDate else {
                    return false
                }
                return (releaseDate.compare(startDate) == .orderedDescending) && (releaseDate.compare(endDate) == .orderedAscending)
            }
            
            return filteredItems.sorted {
                return $0.releaseDate! < $1.releaseDate!
            }
        }
        return []
    }
}
