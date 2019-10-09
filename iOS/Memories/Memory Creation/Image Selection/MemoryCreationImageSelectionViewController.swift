//
//  MemoryCreationImageSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import Tatsi
import Photos

/// `MemoryCreationImageSelectionViewController`: Allows user to select the images to add to the memory.
class MemoryCreationImageSelectionViewController: UIViewController {

    //MARK: IBOutlets and Properties
    @IBOutlet weak var collectionView: ImageSelectionCollectionView!
    @IBOutlet weak var nextButton: UIButton!
    
    ///The image picker controller.
    var imagePicker: TatsiPickerViewController!
    
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
    
    ///Presents the image picker, giving it the proper callbacks for selection
    func presentImagePicker() {
        self.imagePicker = TatsiPickerViewController()
        self.imagePicker?.pickerDelegate = self
        self.present(self.imagePicker!, animated: true, completion: nil)
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

extension MemoryCreationImageSelectionViewController: TatsiPickerViewControllerDelegate {
    func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
        pickerViewController.dismiss(animated: true, completion: nil)
        let manager = PHImageManager.default()
        for asset in assets {
            self.collectionView.images.append(nil)

            //Configure the request options.
            let requestOptions = PHImageRequestOptions()
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.version = .current
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isSynchronous = false

            //Request the image.
            manager.requestImage(for: asset, targetSize: CGSize.square(withSideLength: 2000), contentMode: .aspectFit, options: requestOptions) { (image, info) in
                guard let image = image, let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, !isDegraded else { return }
                DispatchQueue.main.async {
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
        }
        self.imagePicker = nil
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }

}
