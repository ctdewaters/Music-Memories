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
        //Show a processing HUD while we add the images to the memory.
        let content = CDHUD.ContentType.processing(title: "Processing Images")
        CDHUD.shared.present(animated: true, withContentType: content, toView: memoryComposeVC.view)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            //Add images to the memory.
            for image in self.collectionView.images {
                let mkImage = MKCoreData.shared.createNewMKImage()
                if let image = image {
                    mkImage.set(withUIImage: image)
                }
                mkImage.memory = memoryComposeVC.memory
            }
            //Save the memory (no turning back at this point).
            memoryComposeVC.memory.save()
        }
        
        CDHUD.shared.dismiss(animated: true, afterDelay: 0)
        
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
            
            
            for asset in selectedAssets {
                self.collectionView.images.append(nil)
                self.getAssetImage(withAsset: asset, forSize: CGSize(width: asset.pixelHeight, height: asset.pixelWidth), withCompletion: { (image) in
                    DispatchQueue.main.async {
                        if let image = image {
                            //Replace a nil in images with this image, and reload data.
                            for i in 0..<self.collectionView.images.count {
                                if self.collectionView.images[i] == nil {
                                    self.collectionView.images[i] = image
                                    break
                                }
                            }
                            self.collectionView.reloadData()
                        }
                    }
                })
            }
            
            self.collectionView.imagePicker = nil
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }, completion: nil)
    }
    
    func getAssetImage(withAsset asset: PHAsset, forSize size: CGSize, withCompletion completion: @escaping (UIImage?) -> Void) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail: UIImage?
        option.isSynchronous = false
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result
            completion(thumbnail)
        })
    }
}

