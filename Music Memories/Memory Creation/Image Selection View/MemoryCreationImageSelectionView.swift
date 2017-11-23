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

class MemoryCreationImageSelectionView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: ImageSelectionCollectionView!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.collectionView.selectionDelegate = self
        self.collectionView.backgroundColor = .clear
    }
}

extension MemoryCreationImageSelectionView: ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionViewDidSignalForPhotoLibrary() {
        //Construct the image picker
        self.collectionView.setupImagePicker()
        //Present the image picker controller.
        memoryComposeVC.bs_presentImagePickerController(self.collectionView.imagePicker, animated: true, select: nil, deselect: nil, cancel: nil, finish: { (selectedAssets) in
            let images: [UIImage] = selectedAssets.map {
                return self.getAssetImage(withAsset: $0, forSize: CGSize(width: $0.pixelHeight, height: $0.pixelWidth))
            }
            self.collectionView.imagePicker = nil
            DispatchQueue.main.async {
                self.collectionView.images = images
                self.collectionView.reloadData()
            }
        }, completion: nil)
    }
    
    func getAssetImage(withAsset asset: PHAsset, forSize size: CGSize) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result ?? UIImage()
        })
        return thumbnail
    }
}

