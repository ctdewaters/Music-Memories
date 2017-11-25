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
    @IBOutlet weak var createMemoryButton: UIButton!
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
        self.createMemoryButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        
        self.collectionView.reloadData()
    }
    
    func setupMediaPicker() {
        self.mediaPicker = MPMediaPickerController(mediaTypes: .music)
        self.mediaPicker.allowsPickingMultipleItems = true
        self.mediaPicker.delegate = self
        self.mediaPicker.view.backgroundColor = .black
        
    }
}

//MARK: - MPMediaPickerControllerDelegate
extension MemoryCreationTrackSelectionView: MPMediaPickerControllerDelegate {
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        self.collectionView.items.append(contentsOf: mediaItemCollection.items)
    }
}
