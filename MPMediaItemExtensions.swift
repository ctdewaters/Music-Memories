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
                ($0.dateAdded.compare(startDate) == .orderedDescending) && ($0.dateAdded.compare(endDate) == .orderedAscending)
            }
            return filteredItems
        }
        return []
    }
}
