//
//  MemoryComposeEventSelectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class MemoryCreationEventSelectionView: MemoryCreationView, EventsCollectionViewDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var eventsCollectionView: EventsCollectionView!
    @IBOutlet weak var calendarsCollectionView: CalendarsCollectionView!
    @IBOutlet weak var backButton: UIButton!
    
    ///The event store.
    let eventStore = EKEventStore()
    
    ///The events to display.
    var events = [EKEvent]()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set the event store in the events collection view.
        self.eventsCollectionView.eventStore = self.eventStore
        self.eventsCollectionView.selectionDelegate = self
        
        //Set the delegate.
        self.calendarsCollectionView.calendarDelegate = self.eventsCollectionView
        
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
        
        //Button setup.
        self.backButton.backgroundColor = Settings.shared.textColor
        self.backButton.layer.cornerRadius = 10

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
    
    
    @IBAction func back(_ sender: Any) {
        //Dismiss
        memoryComposeVC?.dismissView()
    }
    
    //MARK: - EventsCollectionViewDelegate
    func eventsCollectionView(_ collectionView: EventsCollectionView, didSelectEvent event: EKEvent) {
        guard let currentRoute = memoryComposeVC?.currentRoute else {
            return
        }
        
        //Set the event in the next view.
        if let eventMetadataView = currentRoute[memoryComposeVC?.currentIndex ?? 1] as? MemoryCreationEventMetadataView {
            eventMetadataView.event = event
            
            //Set the start and end date for the memory.
            memoryComposeVC?.memory?.startDate = event.startDate
            memoryComposeVC?.memory?.endDate = event.endDate
            
            memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "We have selected a title and description from the calendar event you chose.")
        }
    }
}
