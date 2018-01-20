//
//  EventsCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class EventsCollectionView: UICollectionView, CalendarsCollectionViewDelegate {
    
    ///The event store (created in the superview).
    var eventStore: EKEventStore?

    //MARK: - CalendarsCollectionViewDelegate
    func calendarsCollectionViewDidUpdate(_ collectionView: CalendarsCollectionView) {
        print(collectionView.selectedCalendars.map {
            
            return $0.title
        })
        
        let startDate = NSDate(timeIntervalSinceNow: -365*24*3600 * 75)
        let endDate = NSDate(timeIntervalSinceNow: +365*24*3600 * 15)
        
        let predicate = eventStore!.predicateForEvents(withStart: startDate as Date, end: endDate as Date, calendars: collectionView.selectedCalendars)
        
        let events = eventStore!.events(matching: predicate)

        for event in events {
            print(event.title)
        }
        print("HELLO WORLD")
    }
}
