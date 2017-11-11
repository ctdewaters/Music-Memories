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
    
    let rowHeight: CGFloat = 70
    
    func set(withMemory memory: MKMemory) {
        self.delegate = self
        self.dataSource = self
        
        let nib = UINib(nibName: "MemoryItemCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "memoryItemCell")
        let editNib = UINib(nibName: "EditCollectionViewCell", bundle: nil)
        self.register(editNib, forCellWithReuseIdentifier: "editCell")
        
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
        self.reloadData()
    }

    
    //MARK: - UICollectionViewDelegate & DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return memory.items?.count ?? 0
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            //Section 0, album artwork
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            cell.backgroundColor = themeColor
            cell.clipsToBounds = true
            cell.layer.cornerRadius = 10
            return cell
        }
        else if indexPath.section == 1 {
            //Section 1, songs and edit button.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoryItemCell", for: indexPath) as! MemoryItemCollectionViewCell
            
            let thisItem = self.items[indexPath.row]
            cell.set(withMemoryItem: thisItem)
            
            return cell
        }
        //Section 2, edit cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editCell", for: indexPath) as! EditCollectionViewCell
        
        return cell
        
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: self.frame.width * 0.7, height: self.frame.width * 0.7)
        }
        if indexPath.section == 2 {
            return CGSize(width: self.frame.width * 0.7, height: 50)
        }
        return CGSize(width: self.frame.width, height: rowHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    
}
