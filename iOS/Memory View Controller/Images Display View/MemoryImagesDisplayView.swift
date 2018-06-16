//
//  MemoryImagesDisplayView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/5/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryImagesDisplayView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properties
    ///The collection view that will display the images.
    var collectionView: UICollectionView!
    
    ///Reference to the associated memory.
    weak var memory: MKMemory?
    
    ///Array of available images to display.
    private var memoryImages: [UIImage]?
    
    //MARK: - UIView overrides
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Setup the collection view.
        let layout = NFMCollectionViewFlowLayout()
        layout.equallySpaceCells = false
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.addSubview(self.collectionView)
        self.collectionView.bindFrameToSuperviewBounds()
        self.collectionView.backgroundColor = .clear
        self.backgroundColor = .clear
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.isScrollEnabled = false
        self.collectionView.isUserInteractionEnabled = false
        
        //Register cell class.
        self.collectionView.register(MemoryImagesDisplayCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    func set(withMemory memory: MKMemory) {
        //Set the memory.
        self.memory = memory
        let imageCount = self.memory?.images?.count ?? 1
        let frame = self.frame
        
        //Set the memory images.
        DispatchQueue.global(qos: .background).async {
            self.memoryImages = self.memory?.images?.map {
                let imageSize = CGSize.square(withSideLength: frame.width * 3 / CGFloat(imageCount))
                return $0.uiImage(withSize: imageSize) ?? UIImage()
            }
            
            if self.memoryImages?.count == 0 {
                self.memoryImages?.append(#imageLiteral(resourceName: "logo500").scale(toSize: CGSize.square(withSideLength: frame.width * 3)) ?? UIImage())
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Reload collection view.
        self.collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            cell.set(withImage: memoryImages[indexPath.item])
        }
        
        cell.backgroundColor = .clear
        
        return cell
    }
    
    //Item size.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let memoryImages = self.memoryImages else {
            return .zero
        }
        
        //Greater than three images.
        if memoryImages.count > 3 {
            //Size all cells into four equal sizes.
            let width: CGFloat = self.frame.width / 2 - 0.5
            return CGSize(width: width, height: width)
        }
        //Three images.
        else if memoryImages.count == 3 {
            //Top row will contain two images, bottom row will contain one.
            //Each row has equal height, both items on top row will have half the width of the bottom item.
            
            //Bottom row.
            if indexPath.item == 2 {
                let width: CGFloat = self.frame.width - 0.5
                let height: CGFloat = self.frame.height / 2 - 0.5
                return CGSize(width: width, height: height)
            }
            //Top row.
            let width: CGFloat = self.frame.height / 2 - 0.5
            return CGSize(width: width, height: width)
        }
        //Two images.
        else if memoryImages.count == 2 {
            //Two equally sized cells.
            let width = (self.frame.width / 2) - 0.5
            let height = (self.frame.height * 1.1) - 0.5
            return CGSize(width: width, height: height)
        }
        //One image.
        return self.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.5
    }
}
