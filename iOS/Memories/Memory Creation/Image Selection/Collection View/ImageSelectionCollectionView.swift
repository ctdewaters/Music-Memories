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
    func imageSelectionCollectionView(collectionView: ImageSelectionCollectionView, didSignalDeletionForImageAtIndex index: Int)
}

class ImageSelectionCollectionView: UICollectionView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    //MARK: - Properties
    ///The images to display.
    var images = [UIImage?]()
    
    ///The delgate object.
    var selectionDelegate: ImageSelectionCollectionViewDelegate?
    
    //The size of each cell.
    var cellSize: CGSize!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set delegate and data source.
        self.delegate = self
        self.dataSource = self
        self.contentInset = UIEdgeInsets(top: 16, left: 7, bottom: 0, right: 7)
                        
        let imageCell = UINib(nibName: "ImageSelectionCollectionViewCell", bundle: nil)
        self.register(imageCell, forCellWithReuseIdentifier: "imageCell")
        
        // Layout setup.
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = true
        self.setCollectionViewLayout(layout, animated: false)
        
    }
    
        
    //MARK: - UICollectionView Delegate and Data Source.
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageSelectionCollectionViewCell
        if let image = images[indexPath.item] {
            cell.showActivityIndicator(false)
            cell.imageView.image = image
        }
        else {
            cell.showActivityIndicator(true)
        }
        
        
        cell.index = indexPath.item
        cell.deleteCallback = {
            self.images.remove(at: indexPath.item)
            self.selectionDelegate?.imageSelectionCollectionView(collectionView: self, didSignalDeletionForImageAtIndex: indexPath.item)
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let usableWidth = (self.frame.width - 28.1)
        return CGSize(width: usableWidth / 3, height: usableWidth / 3)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }

}

extension ImageSelectionCollectionViewDelegate {
    func imageSelectionCollectionViewDidSignalForPhotoLibrary() {}
    func imageSelectionCollectionView(collectionView: ImageSelectionCollectionView, didSignalDeletionForImageAtIndex index: Int) {}
}
