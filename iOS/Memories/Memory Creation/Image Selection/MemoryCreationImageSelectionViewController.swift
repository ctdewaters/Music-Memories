//
//  MemoryCreationImageSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import BSImagePicker
import Photos

/// `MemoryCreationImageSelectionViewController`: Allows user to select the images to add to the memory.
class MemoryCreationImageSelectionViewController: UIViewController {

    //MARK: IBOutlets and Properties
    @IBOutlet weak var collectionView: ImageSelectionCollectionView!
    @IBOutlet weak var nextButton: UIButton!
    
    ///The image picker controller.
    var imagePicker: BSImagePickerViewController!
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.backgroundColor = .clear
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        self.nextButton.frame.size = CGSize.square(withSideLength: 30)
        self.nextButton.cornerRadius = 15

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Delete all stored images when coming to this view controller.
        MemoryCreationData.shared.images?.removeAll()
    }
    
    //MARK: BSImagePicker Functions
    ///Sets up the image picker controller.
    func setupImagePicker() {
        self.imagePicker = BSImagePickerViewController()
        self.imagePicker.albumButton.tintColor = .white
        
        self.imagePicker.backgroundColor = .background
        self.imagePicker.settings.selectionFillColor = .theme
        self.imagePicker.albumButton.setTitleColor(.theme, for: .normal)
    }
    
    ///Presents the image picker, giving it the proper callbacks for selection
    func presentImagePicker() {
        //Construct the image picker
        self.setupImagePicker()
        
        //Present the image picker controller.
        self.bs_presentImagePickerController(self.imagePicker, animated: true, select: nil, deselect: nil, cancel: nil, finish: { (selectedAssets) in
            for asset in selectedAssets {
                self.collectionView.images.append(nil)
                self.getAssetImage(withAsset: asset, forSize: CGSize(width: 650, height: 650), withCompletion: { (image) in
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

            self.imagePicker = nil
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
    
    //MARK: IBActions
    @IBAction func openImagePicker(_ sender: Any) {
        self.presentImagePicker()
    }
    
    @IBAction func next(_ sender: Any) {
        var images = [UIImage]()

        for image in self.collectionView.images {
            if let image = image {
                images.append(image)
            }
        }
        MemoryCreationData.shared.images = images
    }
}
