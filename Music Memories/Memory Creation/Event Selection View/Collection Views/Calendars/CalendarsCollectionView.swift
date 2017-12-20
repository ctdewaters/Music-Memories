//
//  CalendarsCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class CalendarsCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properites
    
    ///The calendars to display.
    var calendars = [EKCalendar]()
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Set delegate and data source.
        self.delegate = self
        self.dataSource = self
        
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        layout.scrollDirection = .horizontal
        self.setCollectionViewLayout(layout, animated: false)
        
        
        //Register nib.
        let nib = UINib(nibName: "CalendarsCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "cell")
    }
    
    //MARK: - Reloading
    func reload(withEventStore eventStore: EKEventStore) {
        self.calendars = self.retrieveCalendars(withEventStore: eventStore)
        self.reloadData()
    }
    
    //MARK: - UICollectionViewDelegate and DataSource
    //Number of cells.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.calendars.count
    }
    
    //Cell creation.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarsCollectionViewCell
        cell.set(withCalendar: self.calendars[indexPath.item])
        return cell
    }
    
    //Cell size.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = self.frame.height * 0.7
        let width: CGFloat = self.calendars[indexPath.item].title.width(withConstraintedHeight: 21, font: CalendarsCollectionViewCell.font) + 20
        return CGSize(width: width, height: height)
    }
    
    //MARK: - Calendar retrieval.
    func retrieveCalendars(withEventStore eventStore: EKEventStore) -> [EKCalendar] {
        return eventStore.calendars(for: .event).sorted {
            $0.title < $1.title
        }
    }

}
