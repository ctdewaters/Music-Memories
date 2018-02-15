//
//  ImageSelectionCollectionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/22/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import BSImagePicker

protocol ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionViewDidSignalForPhotoLibrary()
}

class ImageSelectionCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    //MARK: - Properties
    ///The images to display.
    var images = [UIImage?]()
    
    ///The image picker controller.
    var imagePicker: BSImagePickerViewController!
    
    ///The delgate object.
    var selectionDelegate: ImageSelectionCollectionViewDelegate?
    
    //The size of each cell.
    var cellSize: CGSize!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set delegate and data source.
        self.delegate = self
        self.dataSource = self
                
        //Register nibs.
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.register(addMemoryNib, forCellWithReuseIdentifier: "addImagesCell")
        
        let imageCell = UINib(nibName: "ImageSelectionCollectionViewCell", bundle: nil)
        self.register(imageCell, forCellWithReuseIdentifier: "imageCell")
        
        // Layout setup.
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        self.setCollectionViewLayout(layout, animated: false)
    }
    
    
    ///Sets up the image picker controller.
    func setupImagePicker() {
        self.imagePicker = BSImagePickerViewController()
        self.imagePicker.albumButton.tintColor = .white
        self.imagePicker.modalPresentationStyle = .overCurrentContext
        
        self.imagePicker.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.imagePicker.settings.selectionFillColor = .themeColor
        self.imagePicker.albumButton.setTitleColor(.themeColor, for: .normal)
        
        self.imagePicker.navigationBar.barStyle = Settings.shared.darkMode ? .black : .default
        self.imagePicker.navigationBar.tintColor = .themeColor
        
    }
    
    //MARK: - UICollectionView Delegate and Data Source.
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            ///Add item cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addImagesCell", for: indexPath) as! AddMemoryCell
            cell.label.text = "Add Images"
            cell.label.font = cell.label.font.withSize(12)
            cell.cornerRadius = 11
            return cell
        }
        ///Image cell.
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageSelectionCollectionViewCell
        if let image = images[indexPath.item - 1] {
            cell.showActivityIndicator(false)
            cell.imageView.image = image
        }
        else {
            cell.showActivityIndicator(true)
        }
        
        
        cell.index = indexPath.item - 1
        cell.deleteCallback = {
            _ = self.images.remove(at: indexPath.item - 1)
            self.performBatchUpdates({
                self.deleteItems(at: [indexPath])
            }) { complete in
                if complete {
                    self.reloadData()
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            self.selectionDelegate?.imageSelectionCollectionViewDidSignalForPhotoLibrary()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: UIScreen.main.bounds.width * 0.75, height: 45)
        }
        return CGSize(width: self.frame.width / 3 - 10, height: self.frame.height / 3 - 10)
    }

}
