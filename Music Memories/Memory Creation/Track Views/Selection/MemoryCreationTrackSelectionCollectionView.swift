//
//  MemoryCreationTrackSelectionCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

protocol MemoryCreationTrackSelectionCollectionViewDelegate {
    func trackCollectionViewDidSignalForMediaPicker()
}

class MemoryCreationTrackSelectionCollectionView: UICollectionView {
    
    ///The currently selected media items.
    var selectedItems = [MPMediaItem]()
    //The currently displayed media items.
    var items = [MPMediaItem]()
    
    ///The height of each row.
    let rowHeight: CGFloat = 70
    
    var maskLayer: CALayer!
    
    var trackDelegate: MemoryCreationTrackSelectionCollectionViewDelegate?
    
    var cellSelectionStyle: MemoryItemCollectionViewCell.SelectionStyle = .play

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Register nib.
        let nib = UINib(nibName: "MemoryItemCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "cell")
        
        let editNib = UINib(nibName: "EditCollectionViewCell", bundle: nil)
        self.register(editNib, forCellWithReuseIdentifier: "addItemsCell")
        
        //Set delegate and data source.
        self.delegate = self
        self.dataSource = self
        
        self.contentInset.bottom = 25
        self.contentInset.top = 25
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
        gradientLayer.colors = [transparent, opaque, opaque, transparent, opaque]
        gradientLayer.locations = [0, NSNumber(floatLiteral: fadePercentage), NSNumber(floatLiteral: 1 - fadePercentage), 1, 1.00001]
        
        maskLayer.addSublayer(gradientLayer)
        self.superview?.layer.mask = maskLayer
        
        maskLayer.masksToBounds = true
    }
}

//MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource

extension MemoryCreationTrackSelectionCollectionView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if !allowsMultipleSelection {
            return 2
        }
        return 1
    }
    
    //Number of items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 && !allowsMultipleSelection {
            return 1
        }
        return self.items.count
    }
    
    //Cell creation
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 && !allowsMultipleSelection {
            //Add item cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addItemsCell", for: indexPath) as! EditCollectionViewCell
            cell.backgroundColor = .themeColor
            cell.clipsToBounds = true
            cell.layer.cornerRadius = 10
            cell.titleLabel.text = "Add Tracks"
            return cell
        }
        //Media item cell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MemoryItemCollectionViewCell
        cell.selectionStyle = self.cellSelectionStyle
        
        cell.set(withMPMediaItem: self.items[indexPath.item])
        
        if self.cellSelectionStyle == .unselect && self.selectedItems.contains(self.items[indexPath.item]) {
            //Unselct selection style, select the cell if it is in the selected array.
            cell.isMultiSelected = true
            //Animate the checkmark.
            cell.successCheckmark?.strokeEnd = 1
        }
        else {
            //Set selected to false.
            cell.isMultiSelected = false
            //Animate the checkmark.
            cell.successCheckmark?.strokeEnd = 0
        }
        
        return cell
    }
    
    //MARK: - Cell highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? EditCollectionViewCell {
            cell.highlight()
        }
        else if let cell = collectionView.cellForItem(at: indexPath) as? MemoryItemCollectionViewCell {
            cell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? EditCollectionViewCell {
            cell.removeHighlight()
        }
        else if let cell = collectionView.cellForItem(at: indexPath) as? MemoryItemCollectionViewCell {
            cell.removeHighlight()
        }
    }
    
    //MARK: - Flow Layout
    //Size of each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 && !allowsMultipleSelection {
            return CGSize(width: self.frame.width * 0.7, height: 45)
        }
        return CGSize(width: self.frame.width, height: self.rowHeight)
    }

    //Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    
    
    //MARK: - Cell selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 && !allowsMultipleSelection {
            trackDelegate?.trackCollectionViewDidSignalForMediaPicker()
            return
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryItemCollectionViewCell {
            cell.select()
            //Check if we just signaled an item to be deleted.
            if !cell.isMultiSelected {
                //Delete the item from the selected items array.
                self.selectedItems.remove(item: self.items[indexPath.item])
            }
            else {
                //Item added, add the item to the selected items array
                self.selectedItems.append(self.items[indexPath.item])
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryItemCollectionViewCell {
            cell.select()
            //Check if we just signaled an item to be deleted.
            if !cell.isMultiSelected {
                //Delete the item from the selected items array.
                self.selectedItems.remove(item: self.items[indexPath.item])
            }            else {
                //Item added, add the item to the selected items array
                self.selectedItems.append(self.items[indexPath.item])
            }

        }
    }
}

//MARK: - [MPMediaItem] extension
extension Array where Iterator.Element :  MPMediaItem {
    ///Searches the array for a matching MPMediaItem and removes it.
    mutating func remove(item: MPMediaItem) {
        for i in 0..<self.count {
            if i < count && self[i] == item {
                self.remove(at: i)
            }
        }
    }
}
