//
//  LKLibraryManager.swift
//  LibraryKit
//
//  Created by Collin DeWaters on 10/31/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
import MediaPlayer

///`LKLibraryManager`: Manages interactions with a the music library.
@available(iOS 11.0, *)
public class LKLibraryManager {
    
    //MARK: - Properties.
    
    ///The shared instance.
    public static let shared = LKLibraryManager()
    
    ///The earliest year the user added an item to their library.
    private static var earliestYearAdded: Int? {
        set {
            UserDefaults.standard.set(newValue, forKey: "earliestYearAdded")
        }
        get {
            return UserDefaults.standard.integer(forKey: "earliestYearAdded")
        }
    }
    
    //MARK: - Album Retrieval
    
    /// Retrieves all albums, sorted by add date and filtered into a dictionary by year added.
    /// - Parameter completion: A completion block, which will be supplied with the sorted albums by year added as a dictionary.
    public func retrieveYearlySortedAlbums(withCompletion completion: @escaping ([Int : [MPMediaItemCollection]]) -> Void) {
        let query = MPMediaQuery.albums()
        let albums = query.collections
        
        //Set earliest add year, if not previously set.
        if LKLibraryManager.earliestYearAdded == nil || LKLibraryManager.earliestYearAdded == 0 {
            DispatchQueue.global(qos: .background).sync {
                LKLibraryManager.earliestYearAdded = self.earliestAddYear(ofAlbums: albums)
            }
        }
        
        //The number of years to filter.
        let limit = Date().year + 1 - LKLibraryManager.earliestYearAdded!
        
        ///The number of years filtered.
        var counter = 0
        
        ///A dispatch queue to run the filter code on.
        let filterQueue = DispatchQueue(label: "filterQueue", qos: .userInteractive, autoreleaseFrequency: .never, target: nil)
        
        ///The sorted album library, filtered by year added.
        var sortedAlbumLibrary = [Int : [MPMediaItemCollection]]()
        
        for i in 0 ... limit {
            //Calculate the year to filter for.
            let year = LKLibraryManager.earliestYearAdded! + i
            
            //Asynchronously run the filter function.
            filterQueue.async {
                if let filteredAlbums = self.filter(albums: albums, addedInYear: year) {
                    if filteredAlbums.count > 0 {
                        sortedAlbumLibrary[year] = filteredAlbums
                    }
                }
                
                //Iterate the counter.
                counter += 1
                
                if counter == limit {
                    //All years filtered.
                    DispatchQueue.main.async {
                        completion(sortedAlbumLibrary)
                    }
                }
            }
        }
    }
    
    //MARK: - Sorting and Filtering
    
    /// Retrieves the earliest year an album was added.
    /// - Parameter albums: The albums to search through.
    private func earliestAddYear(ofAlbums albums: [MPMediaItemCollection]?) -> Int? {
        print("FINDING EARLIEST ADD YEAR")
        if var albums = albums {
            albums = self.sortByDateAdded(albums) ?? albums
            return albums.last?.representativeItem?.dateAdded.year
        }
        return nil
    }
    
    /// Retrieves all all albums added during the course of a specific year.
    /// - Parameter albums: The albums to filter.
    /// - Parameter year: The year to filter albums added during.
    private func filter(albums: [MPMediaItemCollection]?, addedInYear year: Int) -> [MPMediaItemCollection]? {
        if let albums = albums {
            let filteredAlbums = albums.filter {
                $0.representativeItem?.dateAdded.year == year
            }
            return self.sortByDateAdded(filteredAlbums)
        }
        return nil
    }
    
    /// Sorts an album array by date added.
    /// - Parameter albums: The albums to sort.
    private func sortByDateAdded(_ albums: [MPMediaItemCollection]?) -> [MPMediaItemCollection]? {
        return albums?.sorted {
            $0.representativeItem!.dateAdded > $1.representativeItem!.dateAdded
        }
    }
}
#endif

//MARK: - Date extension.
public extension Date {
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
}
