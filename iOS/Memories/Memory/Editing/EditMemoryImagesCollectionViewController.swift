//
//  EditMemoryImagesCollectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/23/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

/// `EditMemoryImagesCollectionViewController`: View Controller that handles adding and removing images from a memory.
class EditMemoryImagesCollectionViewController: UICollectionViewController {
    
    //MARK: - Properties
    ///The memory, whose images will be dispolayed in  `imageCollectionView`.
    var memory: MKMemory?
    
    ///The full size images to save to the memory when editing is completed.
    var memoryImages = [MKImage]()
    
    ///The image picker.
    var imagePicker: UIImagePickerController?
        
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
                return $0.uiImage() ?? UIImage()
            }
            self.memoryImages = images.map { $0 }
            
            DispatchQueue.main.async {
                self.imageCollectionView?.images = uiImages
                self.imageCollectionView?.reloadData()
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func addImages(_ sender: Any) {
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.allowsEditing = true
        self.imagePicker?.sourceType = .photoLibrary
        self.imagePicker?.mediaTypes = ["public.image"]
        self.imagePicker?.delegate = self
        self.present(self.imagePicker!, animated: true, completion: nil)
    }
}

//MARK: - ImageSelectionCollectionViewDelegate
extension EditMemoryImagesCollectionViewController: ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionView(collectionView: ImageSelectionCollectionView, didSignalDeletionForImageAtIndex index: Int) {
        guard index < self.memoryImages.count else { return }
        let image = self.memoryImages[index]
        image.delete()
        
        self.memoryImages.remove(at: index)
    }
}

//MARK: - UIImagePickerDelegate
extension EditMemoryImagesCollectionViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        var newImage: UIImage?
        if let image = info[.editedImage] as? UIImage {
            newImage = image
        }
        else if let image = info[.originalImage] as? UIImage {
            newImage = image
        }
        guard let usableImage = newImage else { return }
        
        //Create a `MKImage` object.
        let mkImage = MKCoreData.shared.createNewMKImage()
        mkImage.memory = self.memory
        mkImage.imageData = usableImage.compressedData(withQuality: 0.9)
        mkImage.save()
        self.memoryImages.append(mkImage)
        
        //Add the image thumbnail to the collection view.
        self.imageCollectionView?.images.append(usableImage.scale(toSize: CGSize.square(withSideLength: 250)) ?? usableImage)
        self.imageCollectionView?.reloadData()
    }
}
