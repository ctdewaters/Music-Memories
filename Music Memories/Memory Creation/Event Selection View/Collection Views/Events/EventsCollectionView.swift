//
//  EventsCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 12/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

class EventsCollectionView: UICollectionView, CalendarsCollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    ///The event store (created in the superview).
    weak var eventStore: EKEventStore?
    
    ///The events to display.
    var events = [EKEvent]()
    
    private var maskLayer: CALayer!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set delegate and data source
        self.delegate = self
        self.dataSource = self
        
        //Flow layout
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        layout.itemSize = CGSize(width: self.frame.width, height: 90)
        self.setCollectionViewLayout(layout, animated: false)
        
        //Register nib
        let nib = UINib(nibName: "EventsCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "cell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.maskLayer == nil {
            self.setupFade()
        }
    }
    
    let fadePercentage: Double = 0.07
    func setupFade() {
        let transparent = UIColor.clear.cgColor
        let opaque = UIColor.black.cgColor
        
        maskLayer = CALayer()
        maskLayer.frame = self.frame
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: self.bounds.origin.x, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        gradientLayer.colors = [transparent, opaque, opaque, transparent, transparent]
        gradientLayer.locations = [0, NSNumber(floatLiteral: fadePercentage), NSNumber(floatLiteral: 1 - fadePercentage), 1, 1.00001]
        
        maskLayer.addSublayer(gradientLayer)
        self.superview?.layer.mask = maskLayer
        
        maskLayer.masksToBounds = true
    }

    //MARK: - CalendarsCollectionViewDelegate
    func calendarsCollectionViewDidUpdate(_ collectionView: CalendarsCollectionView) {
        
        //Event search date range.
        let startDate = Date(timeIntervalSinceNow: -4 * 365 * 24 * 3600)
        let endDate = Date()
        
        //Creating the search predicate.
        let predicate = eventStore!.predicateForEvents(withStart: startDate, end: endDate, calendars: collectionView.selectedCalendars)
        
        //Event retrieval
        self.events = eventStore!.events(matching: predicate).sorted {
            $0.startDate < $1.startDate
        }
        
        self.contentInset.top = 20
        
        //Reload
        self.reloadData()
    }
    
    //MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.events.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! EventsCollectionViewCell
        cell.setup(withEvent: self.events[indexPath.item])
        return cell
    }
    
    //MARK: - Cell Highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? EventsCollectionViewCell {
            cell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? EventsCollectionViewCell {
            cell.unhighlight()
        }
    }
}
