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
        if let itemsArray = self.itemsArray {
            return itemsArray
        }
        var array = [MKMemoryItem]()
        for item in memory.items! {
            array.append(item)
        }
        array = array.sorted {
            $0.mpMediaItem!.playCount > $1.mpMediaItem!.playCount
        }
        self.itemsArray = array
        return array
    }
    
    ///Called when the collection view scrolls.
    var scrollCallback: ((CGFloat)->Void)?
    
    var itemsArray: [MKMemoryItem]?
    
    let rowHeight: CGFloat = 70
    
    func set(withMemory memory: MKMemory) {
        self.delegate = self
        self.dataSource = self
        
        print(memory.items?.count)
        
        //Collection view nib registration
        let nib = UINib(nibName: "MemoryItemCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "memoryItemCell")
        let editNib = UINib(nibName: "EditCollectionViewCell", bundle: nil)
        self.register(editNib, forCellWithReuseIdentifier: "editCell")

        //Layout setup
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        self.setCollectionViewLayout(layout, animated: false)
        
        memory.removeAllSongsNotInLibrary()
        self.memory = memory
        
        self.reload()
    }
    
    func reload() {
        self.reloadData()
    }

    
    //MARK: - UICollectionViewDelegate & DataSource
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollCallback?(scrollView.contentOffset.y)
    }
    
    ///Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    ///Number of cells in each section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return memory.items?.count ?? 0
        }
        return 1
    }
    
    ///Cell creation
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            //Section 0, songs and edit button.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoryItemCell", for: indexPath) as! MemoryItemCollectionViewCell
            
            let thisItem = self.items[indexPath.item]
            cell.set(withMemoryItem: thisItem)
            
            return cell
        }
        //Section 1, edit cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editCell", for: indexPath) as! EditCollectionViewCell
        
        return cell
        
    }

    //Size of each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 1 {
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
    
    //MARK: - Selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            //Song selected, play array starting at that index.

            ///Retrieve the array of songs starting at the selected index.
            let array = self.items.subarray(startingAtIndex: indexPath.item)
            
            //Convert MKMemoryItem to MPMediaItem.
            let arrayItems = array.map {
                return $0.mpMediaItem!
            }
            
            //Play the array.
            MKMusicPlaybackHandler.play(items: arrayItems)
        }
    }
    
}

extension Array {
    var copy: Array {
        var copiedArray = Array()
        for item in self {
            copiedArray.append(item)
        }
        return copiedArray
    }
    
    func subarray(startingAtIndex index: Int) -> Array {
        var copiedArray = Array()
        for i in 0..<count {
            if i >= index {
                copiedArray.append(self[i])
            }
        }
        return copiedArray
    }
}
