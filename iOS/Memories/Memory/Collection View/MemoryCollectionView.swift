//
//  MemoryCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer

///`MemoryCollectionView`: collection view displays a `MKMemory` and its contents, along with play and edit options.
class MemoryCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, MPMediaPickerControllerDelegate {

    ///The associated MKMemory reference.
    weak var memory: MKMemory?
    
    ///The items to display.
    var items: [MKMemoryItem] {
        if let itemsArray = self.itemsArray {
            return itemsArray
        }
        var array = [MKMemoryItem]()
        
        if let items = memory?.items {
            for item in items {
                array.append(item)
            }
        }
        else {
            return []
        }
        
        array = array.filter {
            return $0.mpMediaItem != nil
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
    
    ///Indicates if the user is currently editing this memory.
    var isEditing = false
    
    ///MediaPicker for selecting songs to add to this memory.
    weak var mediaPicker: MPMediaPickerController?
    
    //MARK: - Section Convenience Variables
    var infoSection: Int {
        return 0
    }
    var actionsSection: Int {
        return 2
    }
    var itemsSection: Int {
        return 1
    }
    
    weak var vc: MemoryViewController? {
        return self.viewController() as? MemoryViewController
    }
    
    //MARK: - UICollectionView overrides.
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    //MARK: - Setup
    ///Sets up the collection view with a given MKMemory object.
    func set(withMemory memory: MKMemory) {
        self.delegate = self
        self.dataSource = self
        
        //Register nibs.
        //Collection view nib registration
        let infoNib = UINib(nibName: "MemoryInfoCollectionViewCell", bundle: nil)
        self.register(infoNib, forCellWithReuseIdentifier: "infoCell")
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
        return 3
    }
    
    ///Number of cells in each section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == self.itemsSection {
            return self.memory?.items?.count ?? 0
        }
        if section == self.actionsSection {
            return self.isEditing ? 1 : 0
        }
        //Info section.
        return self.isEditing ? 2 : 1
    }
    
    ///Cell creation
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == itemsSection {
            //Section 0, play and edit button.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoryItemCell", for: indexPath) as! MemoryItemCollectionViewCell
            
            let thisItem = self.items[indexPath.item]
            cell.selectionStyle = self.isEditing ? .delete : .play
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
        else if indexPath.section == actionsSection {
            //Delete cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addMemoryCell", for: indexPath) as! AddMemoryCell
            cell.icon.image = #imageLiteral(resourceName: "deleteIcon")
            cell.label.text = "Delete"
            cell.backgroundColor = .error
            cell.layoutIfNeeded()
            return cell
        }
        //Section 0, info cell or add songs cell.
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "infoCell", for: indexPath) as! MemoryInfoCollectionViewCell
            if self.memory != nil {
                cell.setup(withMemory: self.memory!)
            }
            
            if self.isEditing {
                cell.descriptionView.clipsToBounds = true
                cell.descriptionView.layer.cornerRadius = 10
                cell.descriptionView.backgroundColor = Settings.shared.accessoryTextColor.withAlphaComponent(0.25)
                cell.descriptionView.isEditable = true
            }
            else {
                cell.descriptionView.layer.cornerRadius = 10
                cell.descriptionView.backgroundColor = .clear
                cell.descriptionView.isEditable = false
            }
            
            cell.backgroundColor = .clear
            return cell
        }
        
        //Add songs cell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addMemoryCell", for: indexPath) as! AddMemoryCell
        cell.icon.image =  #imageLiteral(resourceName: "addIcon")
        cell.label.text = "Add Songs"
        cell.backgroundColor = .theme
        cell.layoutIfNeeded()
        return cell
    }

    //Size of each item
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == self.actionsSection {
            return CGSize(width: (self.frame.width - 20), height: 45)
        }
        else if indexPath.section == self.itemsSection {
            return CGSize(width: self.frame.width, height: rowHeight)
        }
        
        //Info section.
        
        if indexPath.item == 1 {
            return CGSize(width: (self.frame.width - 20), height: 45)
        }
        
        if self.memory?.desc == "" || self.memory?.desc == nil {
            return CGSize(width: self.frame.width, height: self.isEditing ? 70 : 30)
        }
        if let cell = self.cellForItem(at: IndexPath(item: 0, section: infoSection)) as? MemoryInfoCollectionViewCell {
            let height = 55 + cell.descriptionView.text.height(withConstrainedWidth: self.frame.width - 20, font: UIFont.preferredFont(forTextStyle: .subheadline))
            return CGSize(width: self.frame.width, height: height)
        }
        let height = 55 + (self.memory?.desc ?? "").height(withConstrainedWidth: self.frame.width - 20, font: UIFont.preferredFont(forTextStyle: .subheadline))
        return CGSize(width: self.frame.width, height: height)
    }
    
    //Insets
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == self.actionsSection {
            return UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        }
        else if section == self.itemsSection {
            return UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
        return UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == actionsSection {
            return 10
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    //MARK: - Collection View Cell Highlighting
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //Retrieve the cell
        let cell = collectionView.cellForItem(at: indexPath)
        
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
        if indexPath.section == self.itemsSection {
            if isEditing {
                //Delete song from memory.
                DispatchQueue.global().async {
                    if let thisItem = self.items[indexPath.item].mpMediaItem {
                        self.memory?.remove(mpMediaItem: thisItem)
                    }
                    self.itemsArray?.remove(at: indexPath.item)
                    
                    if self.nowPlayingIndex == indexPath.item {
                        self.nowPlayingIndex = nil
                    }
                    
                    DispatchQueue.main.async {
                        self.performBatchUpdates({
                            self.deleteItems(at: [indexPath])
                        }, completion: nil)
                    }
                }
                return
            }
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
                    if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: itemsSection)) as? MemoryItemCollectionViewCell {
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
            
        else if indexPath.section == self.actionsSection {
            if !isEditing {
                //Play the whole memory.
                if self.memory != nil {
                    MKMusicPlaybackHandler.play(memory: self.memory!)
                }
                return
            }
            //Delete
            //Present the delete action controller
            self.showDeleteActionView()
        }
        
        else if indexPath.section == self.infoSection {
            if indexPath.item == 1 {
                self.mediaPicker = MPMediaPickerController(mediaTypes: .music)
                self.mediaPicker?.delegate = self
                self.mediaPicker?.allowsPickingMultipleItems = true
                self.vc?.present(self.mediaPicker!, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - MPMediaPickerControllerDelegate
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true) {
            self.vc?.headerBlur.effect = nil
            self.vc?.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.vc?.headerBlur.effect = Settings.shared.blurEffect
            }
        }
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        DispatchQueue.global().async {
            for item in mediaItemCollection.items {
                if self.memory != nil && !self.memory!.contains(mpMediaItem: item) {
                    self.memory?.add(mpMediaItem: item)
                }
            }
            self.memory?.save()
            self.itemsArray = nil
            
            DispatchQueue.main.async {
                mediaPicker.dismiss(animated: true) {
                    self.vc?.headerBlur.effect = nil
                    self.vc?.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                        self.vc?.headerBlur.effect = Settings.shared.blurEffect
                    }
                    self.reload()
                }
            }
        }
    }
    
    //MARK: - Delete Action View.
    func showDeleteActionView() {
        let alertController = UIAlertController(title: "Delete Memory?", message: "Are you sure you want to delete the memory \"\(self.memory?.title ?? "")\"? This action cannot be undone.", preferredStyle: UIAlertController.Style.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.memory?.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .delete)
            self.vc?.deleteMemoryAndClose()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.vc?.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Enable / Disable editing.
    func enableEditing(toOn on: Bool) {
        //Check if the title was completely deleted.
        if self.vc?.titleTextView.text == "" {
            //Show error message.
            
            CDHUD.shared.present(animated: true, withContentType: .error(title: "Memories Must Have a Title!"), toView: self.vc?.view ?? UIView(), removeAfterDelay: 2, coverSuperview: true)
            return
        }
        
        //Update the local isEditing property.
        self.isEditing = on
        
        //Toggle title text view.
        self.vc?.titleTextView.isEditable = on
        self.vc?.titleTextView.clipsToBounds = true
        self.vc?.titleTextView.layer.cornerRadius = 12
        
        //Save if we are toggling editing off.
        if !on {
            self.memory?.title = self.vc?.titleTextView.text
            self.memory?.save()
        }
        
        
        UIView.animate(withDuration: 0.2) {
            self.vc?.titleTextView.backgroundColor = on ? Settings.shared.accessoryTextColor.withAlphaComponent(0.75) : .clear
        }
        
        //Toggle info cell.
        if let cell = self.cellForItem(at: IndexPath(row: 0, section: self.infoSection)) as? MemoryInfoCollectionViewCell {
            cell.descriptionView.isEditable = on
            cell.descriptionView.layer.cornerRadius = 10
            cell.descriptionView.clipsToBounds = true
            cell.descriptionView.delegate = self
            
            //Save description update.
            if !on {
                self.memory?.desc = cell.descriptionView.text
                self.memory?.save()
            }
            
            UIView.animate(withDuration: 0.2) {
                cell.descriptionView.backgroundColor = on ? Settings.shared.accessoryTextColor.withAlphaComponent(0.25) : UIColor.clear
            }
        }
        
        //Add or remove cells based on whether editing is enabled.
        self.performBatchUpdates({
            if on {
                self.insertItems(at: [IndexPath(item: 0, section: self.actionsSection), IndexPath(item: 1, section: self.infoSection)])
            }
            else {
                self.deleteItems(at: [IndexPath(item: 0, section: self.actionsSection), IndexPath(item: 1, section: self.infoSection)])
            }
        }, completion: nil)
        
        for cell in self.visibleCells {
            if let itemCell = cell as? MemoryItemCollectionViewCell {
                itemCell.set(selectionStyle: on ? .delete : .play, animated: true)
            }
        }
    }
    
    //MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        self.performBatchUpdates({}, completion: nil)
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
                                    if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: self.itemsSection)) as? MemoryItemCollectionViewCell {
                                        cell.toggleNowPlayingUI(false)
                                    }
                                }
                                else {
                                    return
                                }
                            }
                            
                            //Retrieve the found item's cell.
                            if let cell = self.cellForItem(at: IndexPath(item: i, section: self.itemsSection)) as? MemoryItemCollectionViewCell {
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
        if MKMusicPlaybackHandler.mediaPlayerController.playbackState == .stopped {
            if let nowPlayingIndex = self.nowPlayingIndex {
                if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: itemsSection)) as? MemoryItemCollectionViewCell {
                    cell.toggleNowPlayingUI(false)
                }
            }
            self.nowPlayingIndex = nil
        }
        if let nowPlayingIndex = self.nowPlayingIndex {
            if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: itemsSection)) as? MemoryItemCollectionViewCell {
                cell.updateNowPlayingUIState()
            }
        }
    }
    
    func setNowPlayingToIdle() {
        if let nowPlayingIndex = self.nowPlayingIndex {
            if let cell = self.cellForItem(at: IndexPath(item: nowPlayingIndex, section: itemsSection)) as? MemoryItemCollectionViewCell {
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
