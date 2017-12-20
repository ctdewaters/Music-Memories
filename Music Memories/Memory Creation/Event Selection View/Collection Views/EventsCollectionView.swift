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

    //MARK: - CalendarsCollectionViewDelegate
    func calendarsCollectionViewDidUpdate(_ collectionView: CalendarsCollectionView) {
        print(collectionView.selectedCalendars)
    }
}
