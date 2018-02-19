//
//  MemoryCreationTrackSelectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/23/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer

class MemoryCreationTrackSelectionView: MemoryCreationView {
    //MARK: - IBOutlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var collectionView: MemoryCreationTrackSelectionCollectionView!
    
    ///The media picker.
    var mediaPicker: MPMediaPickerController!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Setup the media picker.
        self.setupMediaPicker()
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.textColor
                button.layer.cornerRadius = 10
            }
        }
        self.nextButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        
        self.collectionView.cellSelectionStyle = .delete
        self.collectionView.trackDelegate = self
        self.collectionView.reloadData()
    }
    
    func setupMediaPicker() {
        self.mediaPicker = MPMediaPickerController(mediaTypes: .music)
        self.mediaPicker.allowsPickingMultipleItems = true
        self.mediaPicker.delegate = self
        self.mediaPicker.view.backgroundColor = .black
        self.mediaPicker.modalPresentationStyle = .overCurrentContext
        
    }
    
    //MARK: - IBActions
    @IBAction func back(_ sender: Any) {
        //Dismiss
        memoryComposeVC?.dismissView()
    }
    
    @IBAction func next(_ sender: Any) {
        DispatchQueue.global().async {
            //Add all the songs to the memory as MKMemoryItems.
            for item in self.collectionView.items {
                if !(memoryComposeVC?.memory?.contains(mpMediaItem: item))! {
                    let mkItem = item.mkMemoryItem
                    mkItem.memory = memoryComposeVC?.memory
                }
            }
            //Save the memory.
            memoryComposeVC?.memory?.save()
            
            DispatchQueue.main.async {
                //Continue to the next view.
                memoryComposeVC?.proceedToNextViewInRoute(withTitle: "New Memory \"\(memoryComposeVC?.memory?.title ?? "")\" Created!", andSubtitle: "Enjoy listening to it now, and in the future!")
            }
        }
    }
}

//MARK: - MPMediaPickerControllerDelegate
extension MemoryCreationTrackSelectionView: MPMediaPickerControllerDelegate {
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        self.collectionView.items.append(contentsOf: mediaItemCollection.items)
        self.collectionView.reloadData()
    }
}

extension MemoryCreationTrackSelectionView: MemoryCreationTrackSelectionCollectionViewDelegate {
    func trackCollectionViewDidSignalForMediaPicker() {
        memoryComposeVC?.present(self.mediaPicker, animated: true, completion: nil)
    }
}
