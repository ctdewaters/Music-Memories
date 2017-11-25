//
//  MemoryCreationTrackSelectionCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/25/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

class MemoryCreationTrackSelectionCollectionView: UICollectionView {
    
    ///The currently selected media items.
    var items = [MPMediaItem]()
    
    ///The height of each row.
    let rowHeight: CGFloat = 70

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
    }
}

//MARK: - UICollectionViewDelegateFlowLayout & UICollectionViewDataSource

extension MemoryCreationTrackSelectionCollectionView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            //Add item cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addItemsCell", for: indexPath) as! EditCollectionViewCell
            cell.backgroundColor = themeColor
            cell.clipsToBounds = true
            cell.layer.cornerRadius = 10
            cell.titleLabel.text = "Add Tracks"
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MemoryItemCollectionViewCell
        cell.set(withMPMediaItem: self.items[indexPath.item])
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
        if indexPath.section == 0 {
            return CGSize(width: self.frame.width * 0.7, height: 45)
        }
        return CGSize(width: self.frame.width, height: self.rowHeight)
    }

    //Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
}
