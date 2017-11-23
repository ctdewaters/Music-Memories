//
//  MemoryCreationImageSelectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/22/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import BSImagePicker
import Photos
import MemoriesKit

class MemoryCreationImageSelectionView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: ImageSelectionCollectionView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.collectionView.selectionDelegate = self
        self.collectionView.backgroundColor = .clear
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.textColor
                button.layer.cornerRadius = 10
            }
        }
        self.nextButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)

    }
    
    //MARK: - IBActions
    
    @IBAction func next(_ sender: UIButton) {
        //Add images to the memory.
        for image in self.collectionView.images {
            let mkImage = MKCoreData.shared.createNewMKImage()
            mkImage.set(withUIImage: image)
            mkImage.memory = memoryComposeVC.memory
        }
        //Save the memory (no turning back at this point).
        memoryComposeVC.memory.save()
        
        
        //Advance to next view in route.
        memoryComposeVC.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Add tracks in your library you associate with this memory.")
    }
    
    @IBAction func back(_ sender: UIButton) {
        memoryComposeVC.dismissView()
    }
}

//MARK: - ImageSelectionCollectionViewDelegate
extension MemoryCreationImageSelectionView: ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionViewDidSignalForPhotoLibrary() {
        //Construct the image picker
        self.collectionView.setupImagePicker()
        //Present the image picker controller.
        memoryComposeVC.bs_presentImagePickerController(self.collectionView.imagePicker, animated: true, select: nil, deselect: nil, cancel: nil, finish: { (selectedAssets) in
            let images: [UIImage] = selectedAssets.map {
                return self.getAssetImage(withAsset: $0, forSize: CGSize(width: $0.pixelHeight, height: $0.pixelWidth)) ?? UIImage()
                }.filter {
                    $0 != UIImage()
            }
            
            self.collectionView.imagePicker = nil
            DispatchQueue.main.async {
                self.collectionView.images.append(contentsOf: images)
                self.collectionView.reloadData()
            }
        }, completion: nil)
    }
    
    func getAssetImage(withAsset asset: PHAsset, forSize size: CGSize) -> UIImage? {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail: UIImage?
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result
        })
        return thumbnail
    }
}

