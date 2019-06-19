//
//  MemoryCreationTrackSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

/// `MemoryCreationTrackSelectionViewController`: Allows user to select songs not retrieved in the track suggestions view controller.
class MemoryCreationTrackSelectionViewController: UIViewController {
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: MemoryCreationTrackSelectionCollectionView!
    @IBOutlet weak var nextButton: UIButton!
    
    var mediaPicker: MPMediaPickerController!
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup the media picker.
        self.setupMediaPicker()
        
        self.nextButton.frame.size = CGSize.square(withSideLength: 30)
        self.nextButton.cornerRadius = 15

        self.collectionView.cellSelectionStyle = .delete
        self.collectionView.reloadData()
    }
    
    //MARK: MPMediaPickerController Setup
    func setupMediaPicker() {
        self.mediaPicker = MPMediaPickerController(mediaTypes: .music)
        self.mediaPicker.allowsPickingMultipleItems = true
        self.mediaPicker.showsCloudItems = true
        self.mediaPicker.showsItemsWithProtectedAssets = true
        self.mediaPicker.delegate = self
        self.mediaPicker.view.backgroundColor = .black
        self.mediaPicker.modalPresentationStyle = .overCurrentContext
    }
    
    //MARK: - IBActions
    @IBAction func next(_ sender: Any) {
        DispatchQueue.global().async {
            //Add all the songs to the memory as MKMemoryItems.
            if let savedMediaItems = MemoryCreationData.shared.mediaItems {
                for item in self.collectionView.items {
                    if !savedMediaItems.contains(item) {
                        MemoryCreationData.shared.mediaItems?.append(item)
                    }
                }
            }
            else {
                MemoryCreationData.shared.mediaItems = self.collectionView.items
            }
        }
    }
    
    @IBAction func openMediaPicker(_ sender: Any) {
        self.present(self.mediaPicker, animated: true, completion: nil)
    }
}

//MARK: - MPMediaPickerControllerDelegate
extension MemoryCreationTrackSelectionViewController: MPMediaPickerControllerDelegate {
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: {
            self.setupMediaPicker()
        })
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: {
            self.setupMediaPicker()
        })
        
        for item in mediaItemCollection.items {
            if !self.collectionView.items.contains(item) {
                self.collectionView.items.append(item)
            }
        }
        self.collectionView.reloadData()
    }
}
