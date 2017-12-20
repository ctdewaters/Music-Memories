//
//  MemoryComposeEventSelectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class MemoryCreationEventSelectionView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var eventsCollectionView: EventsCollectionView!
    @IBOutlet weak var calendarsCollectionView: CalendarsCollectionView!
    
    ///The event store.
    let eventStore = EKEventStore()
    
    ///The events to display.
    var events = [EKEvent]()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Request access to the user's calendar.
        self.requestAccess { authStatus in
            if authStatus == .authorized {
                //Authorized, retrieve events.
                self.calendarsCollectionView.reload(withEventStore: self.eventStore)
            }
            else {
                //Not authorized, show error message.
                
            }
        }
    }
    
    //MARK: - Event retrieval.
    func requestAccess(withCompletion completion: @escaping (EKAuthorizationStatus)->Void) {
        if EKEventStore.authorizationStatus(for: .event) != .notDetermined {
            completion(EKEventStore.authorizationStatus(for: .event))
            return
        }
        
        self.eventStore.requestAccess(to: .event) { (granted, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }

            completion(EKEventStore.authorizationStatus(for: .event))
        }
    }
    
    func retrieveEvents() -> [EKEvent] {
        //Start date is 1900.
        let startDate = Date.distantPast
        
        //End date is five years in the future.
        let endDate = Date.distantFuture
        
        //Create the predicate.
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        
        //Retrieve the events.
        return eventStore.events(matching: predicate)
    }
    
}
