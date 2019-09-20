//
//  MemoryImagesDisplayView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/5/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import CoreData

class MemoryImagesDisplayView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properties
    ///The collection view that will display the images.
    var collectionView: UICollectionView!
    
    ///Reference to the associated memory.
    weak var memory: MKMemory?
    
    ///Array of available images to display.
    var memoryImages: [UIImage]?
    
    ///The storage IDs of the memory's images during the last reload.
    var lastReloadedStorageIDs = Set(["-1"])
    
    //MARK: - UIView overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Setup the collection view.
        
        //Layout setup.
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
                
        //Add the collection view to the view.
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.addSubview(self.collectionView)
        self.collectionView.bindFrameToSuperviewBounds()
        self.collectionView.backgroundColor = .clear
        self.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.isScrollEnabled = false
        self.collectionView.isUserInteractionEnabled = false
        self.collectionView.clipsToBounds = false
        self.clipsToBounds = false
        
        //Register cell class.
        self.collectionView.register(MemoryImagesDisplayCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Reload collection view.
        self.collectionView.reloadData()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Setup and Reloading
    
    ///Sets up the view with a given memory.
    func set(withMemory memory: MKMemory) {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        //Set the memory.
        self.memory = moc.object(with: memory.objectID) as? MKMemory
        
        ///The size at which to retrieve images.
        let imageSize = CGSize.square(withSideLength: self.frame.width * 1.5)
        
        //Set the memory images.
        moc.perform {
            let updatedMemoryImageIDs = Set(self.memory?.images?.map { return $0.storageID ?? "" } ?? ["-1"])
            
            guard updatedMemoryImageIDs != self.lastReloadedStorageIDs else { return }
            self.lastReloadedStorageIDs = updatedMemoryImageIDs
            
            ///Current index in the memory's images.
            var index = 0
            
            ///If true, we have already reloaded the collection view.
            var collectionViewReloaded = false
            
            //Set the images array with a blank array, and reload the collection view.
            self.memoryImages = []
            self.reload()
            
            //Check if there are no memory images.
            DispatchQueue.main.async {
                if self.memory?.images?.count == 0 {
                    //Append the logo, reload and return from the function.
                    self.memoryImages?.append(#imageLiteral(resourceName: "logo500"))
                    self.reload()
                    return
                }
            }
            //Iterate through the memory's images.
            for mkImage in self.memory?.images ?? [] {
                self.memoryImages?.append(mkImage.uiImage(withSize: imageSize) ?? UIImage())
                
                //Check if we have reached the sufficient amount of images to display.
                if self.memoryImages?.count == 4 || self.memoryImages?.count == self.memory?.images?.count {
                    if !collectionViewReloaded {
                        //Reload the collection view.
                        self.reload()
                        collectionViewReloaded = true
                    }
                }
                index += 1
            }
                        
            //If the collection view hasn't been reloaded at this point, reload.
            if !collectionViewReloaded {
                self.reload()
            }
        }
    }
    
    ///Reloads the collection view on the main thread.
    public func reload() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
        
    //MARK: - UICollectionView DelegateFlowLayout and DataSource
    //Number of sections.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //Number of items.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let memoryImages = self.memoryImages else {
            return 0
        }
        if memoryImages.count > 3 {
            return 4
        }
        return memoryImages.count
    }
    
    //Cell creation.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MemoryImagesDisplayCollectionViewCell
        
        //Set the image in the cell.
        if let memoryImages = self.memoryImages {
            if indexPath.item < memoryImages.count {
                cell.set(withImage: memoryImages[indexPath.item])
            }
        }
        
        cell.backgroundColor = .clear
        
        return cell
    }
    
    //Item size.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let memoryImages = self.memoryImages else {
            return .zero
        }
        
        let separatorSize: CGFloat = 0.05
        
        //Greater than three images.
        if memoryImages.count > 3 {
            //Size all cells into four equal sizes.
            let width: CGFloat = self.frame.width / 2 - separatorSize
            return CGSize(width: width - separatorSize, height: width - separatorSize)
        }
        //Three images.
        else if memoryImages.count == 3 {
            //Top row will contain two images, bottom row will contain one.
            //Each row has equal height, both items on top row will have half the width of the bottom item.
            
            //Bottom row.
            if indexPath.item == 2 {
                let width: CGFloat = self.frame.width - 0.5
                let height: CGFloat = self.frame.height / 2 - separatorSize
                return CGSize(width: width - separatorSize, height: height - separatorSize)
            }
            //Top row.
            let width: CGFloat = self.frame.height / 2 - separatorSize
            return CGSize(width: width - separatorSize, height: width - separatorSize)
        }
        //Two images.
        else if memoryImages.count == 2 {
            //Two equally sized cells.
            let width = (self.frame.width / 2) - separatorSize
            let height = (self.frame.height * 1.1) - separatorSize
            return CGSize(width: width - separatorSize, height: height)
        }
        //One image.
        return self.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
