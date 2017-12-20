//
//  CalendarsCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

///CalendarsCollectionViewDelegate: signals when an update occurs in the calendars collection view.
protocol CalendarsCollectionViewDelegate {
    func calendarsCollectionViewDidUpdate(_ collectionView: CalendarsCollectionView)
}

class CalendarsCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properites
    
    ///The calendars to display.
    var calendars = [EKCalendar]()
    
    ///The selected calendars.
    var selectedCalendars = [EKCalendar]()
    
    var calendarDelegate: CalendarsCollectionViewDelegate?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Set delegate and data source.
        self.delegate = self
        self.dataSource = self
        
        //Dont show the scroll indicator.
        self.showsHorizontalScrollIndicator = false
        
        //Allow multiple selection.
        self.allowsMultipleSelection = true
        
        //Set layout.
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
        //Retrieve the calendars.
        self.calendars = self.retrieveCalendars(withEventStore: eventStore)
        //Start with all calendars selected.
        for calendar in self.calendars {
            self.selectedCalendars.append(calendar)
        }
        
        //Reload data.
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
        cell.userSelected = self.selectedCalendars.contains(self.calendars[indexPath.item]) ? false : true
        cell.set(withCalendar: self.calendars[indexPath.item])
        return cell
    }
    
    //Cell size.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = self.frame.height * 0.7
        let width: CGFloat = self.calendars[indexPath.item].title.width(withConstraintedHeight: 21, font: CalendarsCollectionViewCell.font) + 20
        return CGSize(width: width, height: height)
    }
    
    //MARK: - Cell highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarsCollectionViewCell
        cell.highlight(on: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarsCollectionViewCell
        cell.highlight(on: false)
    }
    
    //MARK: - Cell selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarsCollectionViewCell

        if !selectedCalendars.contains(self.calendars[indexPath.item]) {
            //Add the selected calendars to the selected calendars array.
            self.selectedCalendars.append(self.calendars[indexPath.item])
            
            //Set selected property to true.
            cell.userSelected = true
        }
        else {
            //Remove the deselected calendar from the deselected calendars array.
            self.selectedCalendars.remove(calendar: self.calendars[indexPath.item])
            cell.userSelected = false
        }
        
        cell.toggleSelect()
        
        //Call the delegate function.
        self.calendarDelegate?.calendarsCollectionViewDidUpdate(self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarsCollectionViewCell
        
        if !selectedCalendars.contains(self.calendars[indexPath.item]) {
            //Add the selected calendars to the selected calendars array.
            self.selectedCalendars.append(self.calendars[indexPath.item])
            
            //Set selected property to true.
            cell.userSelected = true
        }
        else {
            //Remove the deselected calendar from the deselected calendars array.
            self.selectedCalendars.remove(calendar: self.calendars[indexPath.item])
            cell.userSelected = false
        }
        
        cell.toggleSelect()
        
        //Call the delegate function.
        self.calendarDelegate?.calendarsCollectionViewDidUpdate(self)
    }
    
    //MARK: - Calendar retrieval.
    func retrieveCalendars(withEventStore eventStore: EKEventStore) -> [EKCalendar] {
        return eventStore.calendars(for: .event).sorted {
            $0.title < $1.title
        }
    }

}

//EKCalendar array extension.
extension Array where Iterator.Element : EKCalendar {
    mutating func remove(calendar: EKCalendar) {
        for i in 0..<self.count {
            if i < self.count {
                if self[i] == calendar {
                    self.remove(at: i)
                }
            }
        }
    }
}
