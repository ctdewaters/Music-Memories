//
//  MemorySelectionEventSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/18/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

/// `MemoryCreationEventSelectionViewController`: Allows user to select an event from their calendar to create a memory.
class MemoryCreationEventSelectionViewController: UIViewController, EventsCollectionViewDelegate {
    
    //MARK: IBOutlets
    @IBOutlet weak var calendarsCollectionView: CalendarsCollectionView!
    @IBOutlet weak var eventsCollectionView: EventsCollectionView!
    @IBOutlet weak var notAuthorizedLabel: UILabel!
    @IBOutlet weak var notAuthorizedButton: UIButton!
    
    
    //MARK: Properties
    ///The event store.
    let eventStore = EKEventStore()
    
    ///The events to display.
    var events = [EKEvent]()
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set the event store in the events collection view.
        self.eventsCollectionView.eventStore = self.eventStore
        self.eventsCollectionView.selectionDelegate = self
        
        //Set the delegate.
        self.calendarsCollectionView.calendarDelegate = self.eventsCollectionView
        
        //Request access to the user's calendar.
        self.requestAccess { authStatus in
            if authStatus == .authorized {
                //Authorized, retrieve events.
                DispatchQueue.main.async {
                    self.calendarsCollectionView.reload(withEventStore: self.eventStore)
                    self.notAuthorizedButton.isHidden = true
                    self.notAuthorizedLabel.isHidden = true
                }
            }
            else {
                DispatchQueue.main.async {
                    //Not authorized, show error message.
                    self.notAuthorizedLabel.textColor = .label
                    self.notAuthorizedButton.isHidden = false
                    self.notAuthorizedLabel.isHidden = false
                }
            }
        }
    }
    
    //MARK: - Event Retrieval
    /// Requests access to the user's event store.
    /// - Parameter completion: completion block run when request has been accepted or denied.
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
    
    ///Goes back to the home page.
    @IBAction func back(_ sender: Any) {
        //Dismiss
        memoryComposeVC?.dismissView()
    }
    
    
    //MARK: IBActions
    
    ///Opens the app's settings page.
    @IBAction func openSettings(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        }
    }
    
    //MARK: EventsCollectionViewDelegate
    func eventsCollectionView(_ collectionView: EventsCollectionView, didSelectEvent event: EKEvent) {
        //Set name, description, and dates to the memory creation data.
        MemoryCreationData.shared.name = event.title ?? ""
        MemoryCreationData.shared.desc = event.notes ?? ""
        MemoryCreationData.shared.startDate = event.startDate
        MemoryCreationData.shared.endDate = event.endDate
        
        //Push to title view controller.
        self.performSegue(withIdentifier: "calendarPushTitle", sender: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
