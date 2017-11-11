//
//  MemoryCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    var memory: MKMemory!
    var items: [MKMemoryItem] {
        var array = [MKMemoryItem]()
        for item in memory.items! {
            array.append(item)
        }
        return array
    }
    
    var itemArray = [MKMemoryItem]()
    
    let rowHeight: CGFloat = 70
    
    func set(withMemory memory: MKMemory) {
        self.delegate = self
        self.dataSource = self
        
        //Collection view nib registration
        let nib = UINib(nibName: "MemoryItemCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "memoryItemCell")
        let editNib = UINib(nibName: "EditCollectionViewCell", bundle: nil)
        self.register(editNib, forCellWithReuseIdentifier: "editCell")
        let artworkNib = UINib(nibName: "ArtworkCollectionViewCell", bundle: nil)
        self.register(artworkNib, forCellWithReuseIdentifier: "artworkCell")
        
        //Layout setup
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        self.setCollectionViewLayout(layout, animated: false)
        
        self.memory = memory
        
        let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: true, playCount: 1, maxAddsPerAlbum: 100)
        self.memory.update(withSettings: updateSettings) { (successful) in
            self.memory.syncToUserLibrary {
                print("SYNCED TO LIBRARY")
            }
        }
        self.reload()
    }
    
    func reload() {
        self.itemArray = self.items
        self.reloadData()
    }

    
    //MARK: - UICollectionViewDelegate & DataSource
    
    ///Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    ///Number of cells in each section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return memory.items?.count ?? 0
        }
        return 1
    }
    
    ///Cell creation
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            //Section 0, album artwork
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "artworkCell", for: indexPath) as! ArtworkCollectionViewCell
            cell.playButton.tintColor = themeColor
            cell.layer.cornerRadius = 10
            return cell
        }
        else if indexPath.section == 1 {
            //Section 1, songs and edit button.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoryItemCell", for: indexPath) as! MemoryItemCollectionViewCell
            
            let thisItem = self.itemArray[indexPath.item]
            cell.set(withMemoryItem: thisItem)
            
            return cell
        }
        //Section 2, edit cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editCell", for: indexPath) as! EditCollectionViewCell
        
        return cell
        
    }

    //Size of each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: self.frame.width * 0.7, height: self.frame.width * 0.7)
        }
        if indexPath.section == 2 {
            return CGSize(width: self.frame.width * 0.7, height: 45)
        }
        return CGSize(width: self.frame.width, height: rowHeight)
    }
    
    //Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    
    //MARK: - Collection View Cell Highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //Retrieve the cell
        let cell = collectionView.cellForItem(at: indexPath)
        
        //Try to cast as edit cell
        if let editCell = cell as? EditCollectionViewCell {
            editCell.highlight()
        }
        
        //Try to cast as item cell
        if let itemCell = cell as? MemoryItemCollectionViewCell {
            itemCell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        //Retrieve the cell
        let cell = collectionView.cellForItem(at: indexPath)
        
        //Try to cast as edit cell
        if let editCell = cell as? EditCollectionViewCell {
            editCell.removeHighlight()
        }
        
        //Try to cast as item cell
        if let itemCell = cell as? MemoryItemCollectionViewCell {
            itemCell.removeHighlight()
        }
    }
    
}
