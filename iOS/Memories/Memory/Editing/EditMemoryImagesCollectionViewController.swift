//
//  EditMemoryImagesCollectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/23/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import Tatsi
import Photos

/// `EditMemoryImagesCollectionViewController`: View Controller that handles adding and removing images from a memory.
class EditMemoryImagesCollectionViewController: UICollectionViewController {
    
    //MARK: - Properties
    ///The memory, whose images will be dispolayed in  `imageCollectionView`.
    var memory: MKMemory?
    
    ///The full size images to save to the memory when editing is completed.
    var memoryImages = [MKImage]()
    
    ///The image picker.
    var imagePicker: TatsiPickerViewController?
        
    ///The collection view, casted as an `ImageSelectionCollectionView`.
    var imageCollectionView: ImageSelectionCollectionView? {
        return self.collectionView as? ImageSelectionCollectionView
    }

    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the selection delegate of the image collection view.
        self.imageCollectionView?.selectionDelegate = self
        
        //Setup intial images with the memory images.
        DispatchQueue.global(qos: .userInteractive).async {
            guard let images = self.memory?.images else { return }
            let uiImages = images.map {
                return $0.croppedUIImage() ?? UIImage()
            }
            self.memoryImages = images.map { $0 }
            
            DispatchQueue.main.async {
                self.imageCollectionView?.images = uiImages
                self.imageCollectionView?.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Post reload notifications.
        NotificationCenter.default.post(name: MemoryViewController.reloadNotification, object: nil)
    }
    
    //MARK: - IBActions
    @IBAction func addImages(_ sender: Any) {
        self.imagePicker = TatsiPickerViewController()
        self.imagePicker?.pickerDelegate = self
        self.present(self.imagePicker!, animated: true, completion: nil)
    }
}

//MARK: - ImageSelectionCollectionViewDelegate
extension EditMemoryImagesCollectionViewController: ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionView(collectionView: ImageSelectionCollectionView, didSignalDeletionForImageAtIndex index: Int) {
        guard index < self.memoryImages.count else { return }
        let image = self.memoryImages[index]
        
        //Cloud sync.
        if let imageID = image.storageID, let memoryID = self.memory?.storageID {
            MKCloudManager.delete(imageID: imageID, memoryID: memoryID)
        }
        
        //Delete locally.
        image.delete()
        
        self.memoryImages.remove(at: index)
    }
}

//MARK: - UIImagePickerDelegate
extension EditMemoryImagesCollectionViewController: TatsiPickerViewControllerDelegate {
        
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
        pickerViewController.dismiss(animated: true, completion: nil)
        let manager = PHImageManager.default()
        for asset in assets {
            
            //Configure the request options.
            let requestOptions = PHImageRequestOptions()
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.version = .current
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isSynchronous = false

            //Request the image.
            manager.requestImage(for: asset, targetSize: CGSize.square(withSideLength: 2000), contentMode: .aspectFit, options: requestOptions) { (image, info) in
                guard let image = image, let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded else { return }
                
                //Create a `MKImage` object.
                if let moc = self.memory?.managedObjectContext {
                    let mkImage = MKCoreData.shared.createNewMKImage(inContext: moc)
                    mkImage.memory = self.memory
                    mkImage.set(withUIImage: image)
                    mkImage.save()
                    
                    //Sync with server
                    MKCloudManager.upload(mkImage: mkImage)
                    
                    self.memoryImages.append(mkImage)

                    //Add the image thumbnail to the collection view.
                    self.imageCollectionView?.images.append(image.scaled(to: CGSize.square(withSideLength: 250), scalingMode: .aspectFill))
                    self.imageCollectionView?.reloadData()
                }
            }
        }
    }
}
