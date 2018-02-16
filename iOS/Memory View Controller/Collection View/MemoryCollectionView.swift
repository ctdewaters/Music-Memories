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

    ///The associated MKMemory reference.
    var memory: MKMemory!
    var items: [MKMemoryItem] {
        if let itemsArray = self.itemsArray {
            return itemsArray
        }
        var array = [MKMemoryItem]()
        
        if let items = memory.items {
            for item in items {
                array.append(item)
            }
        }
        else {
            return []
        }
        
        array = array.sorted {
            $0.mpMediaItem!.playCount > $1.mpMediaItem!.playCount
        }
        self.itemsArray = array
        return array
    }
    var itemsArray: [MKMemoryItem]?
    
    ///Called when the collection view scrolls.
    var scrollCallback: ((CGFloat)->Void)?
    
    
    ///The row height for the cells.
    let rowHeight: CGFloat = 70
    
    ///Row index of the currently playing item.
    var nowPlayingIndex: Int?
    
    //MARK: - Setup
    ///Sets up the collection view with a given MKMemory object.
    func set(withMemory memory: MKMemory) {
        self.delegate = self
        self.dataSource = self
        
        //Collection view nib registration
        let nib = UINib(nibName: "MemoryItemCollectionViewCell", bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: "memoryItemCell")
        let editNib = UINib(nibName: "EditCollectionViewCell", bundle: nil)
        self.register(editNib, forCellWithReuseIdentifier: "editCell")
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.register(addMemoryNib, forCellWithReuseIdentifier: "addMemoryCell")

        //Layout setup
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = false
        self.setCollectionViewLayout(layout, animated: false)
        
        //Remove any songs no longer in the user's library from the memory.
        memory.removeAllSongsNotInLibrary()
        self.memory = memory
        
        self.reload()
    }
    
    ///Reloads data.
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
        if section == 1 {
            return memory.items?.count ?? 0
        }
        return 2
    }
    
    ///Cell creation
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1 {
            //Section 0, songs and edit button.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoryItemCell", for: indexPath) as! MemoryItemCollectionViewCell
            
            let thisItem = self.items[indexPath.item]
            cell.set(withMemoryItem: thisItem)
            
            //Check whether to show or hide the now playing UI.
            if indexPath.item == self.nowPlayingIndex || self.items[indexPath.item].persistentIdentifer == "\(MKMusicPlaybackHandler.nowPlayingItem?.persistentID ?? UInt64())" {
                self.nowPlayingIndex = indexPath.item
                cell.toggleNowPlayingUI(true)
            }
            else {
                cell.toggleNowPlayingUI(false)
            }
            
            return cell
        }
        //Section 0, edit cell
        if indexPath.item == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "editCell", for: indexPath) as! EditCollectionViewCell
            
            return cell
        }
        //Play cell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addMemoryCell", for: indexPath) as! AddMemoryCell
        cell.icon.image = #imageLiteral(resourceName: "playIcon")
        cell.label.text = "Play"
        return cell
    }

    //Size of each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: self.frame.width / 2 - 5, height: 45)
        }
        return CGSize(width: self.frame.width, height: rowHeight)
    }
    
    //Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return .zero
        }
        return UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    //MARK: - Collection View Cell Highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //Retrieve the cell
        let cell = collectionView.cellForItem(at: indexPath)
        
        //Try to cast as edit cell
        if let editCell = cell as? EditCollectionViewCell {
            editCell.highlight()
        }
        
        if let addMemoryCell = cell as? AddMemoryCell {
            addMemoryCell.highlight()
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
        
        if let addMemoryCell = cell as? AddMemoryCell {
            addMemoryCell.removeHighlight()
        }
        
        //Try to cast as item cell
        if let itemCell = cell as? MemoryItemCollectionViewCell {
            itemCell.removeHighlight()
        }
    }
    
    //MARK: - Selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            //Play the array.
            DispatchQueue.global().async {
                //Song selected, play array starting at that index.
                ///Retrieve the array of songs starting at the selected index.
                let array = self.items.subarray(startingAtIndex: indexPath.item)
                
                //Convert MKMemoryItem to MPMediaItem.
                let arrayItems = array.map {
                    return $0.mpMediaItem!
                }
                
                MKMusicPlaybackHandler.play(items: arrayItems)
            }
            
            //Remove UI from the previously playing cell, if needed.
            if let nowPlayingIndex = self.nowPlayingIndex {
                if nowPlayingIndex != indexPath.item {
                    if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: 1)) as? MemoryItemCollectionViewCell {
                        cell.toggleNowPlayingUI(false)
                    }
                }
                else {
                    return
                }
            }
            
            if let cell = self.cellForItem(at: indexPath) as? MemoryItemCollectionViewCell {
                self.nowPlayingIndex = indexPath.item
                cell.toggleNowPlayingUI(true)
            }
        }
        else if indexPath.section == 0 {
            if indexPath.item == 0 {
                //Play the whole memory.
                MKMusicPlaybackHandler.play(memory: self.memory)
            }
        }
    }
    
    //MARK: - Now Playing UI Updating
    ///Scans the memory items for the now playing item, and toggles its respective cell's now playing UI.
    func updateNowPlayingUI() {
        
        DispatchQueue.global().async {
            for i in 0..<self.items.count {
                if let persistentIdentifier = self.items[i].persistentIdentifer {
                    if persistentIdentifier == "\(MKMusicPlaybackHandler.nowPlayingItem?.persistentID ?? UInt64())" {
                        DispatchQueue.main.async {
                            //Remove UI of previously playing cell.
                            if let nowPlayingIndex = self.nowPlayingIndex {
                                if nowPlayingIndex != i {
                                    if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: 1)) as? MemoryItemCollectionViewCell {
                                        cell.toggleNowPlayingUI(false)
                                    }
                                }
                                else {
                                    return
                                }
                            }
                            
                            //Retrieve the found item's cell.
                            if let cell = self.cellForItem(at: IndexPath(item: i, section: 1)) as? MemoryItemCollectionViewCell {
                                self.nowPlayingIndex = i
                                //Toggle now playing UI.
                                cell.toggleNowPlayingUI(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //Changes the state of the currently playing cell to match the systemMusicPlayer.
    func updateNowPlayingUIState() {
        print("UPDATING NOW PLAYING STATE \(MKMusicPlaybackHandler.mediaPlayerController.playbackState.rawValue)")
        if MKMusicPlaybackHandler.mediaPlayerController.playbackState == .stopped {
            if let nowPlayingIndex = self.nowPlayingIndex {
                if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: 1)) as? MemoryItemCollectionViewCell {
                    cell.toggleNowPlayingUI(false)
                }
            }
            self.nowPlayingIndex = nil
        }
        if let nowPlayingIndex = self.nowPlayingIndex {
            if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: 1)) as? MemoryItemCollectionViewCell {
                cell.updateNowPlayingUIState()
            }
        }
    }
    
    func setNowPlayingToIdle() {
        if let nowPlayingIndex = self.nowPlayingIndex {
            if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: 1)) as? MemoryItemCollectionViewCell {
                cell.nowPlayingBlurPropertyAnimator?.stopAnimation(true)
                cell.nowPlayingBlurPropertyAnimator?.finishAnimation(at: .current)
                cell.nowPlayingBlurPropertyAnimator = nil
            }
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
