//
//  MemoryCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import CoreData

/// `MemoryCell`: Displays an MKMemory object in the memories view controller's collection view.
class MemoryCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var visibleCellView: UIView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var dynamicMemoryIcon: UIImageView!
    @IBOutlet weak var dynamicMemoryLabel: UILabel!
    @IBOutlet weak var image: UIView!
    
    ///The index path of this cell.
    var indexPath: IndexPath!
    
    ///Reference to associated memory.
    weak var memory: MKMemory?
    
    ///The image viewer that will display the images for this memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set corner radius.
        self.visibleCellView.layer.cornerRadius = 7
        
        //Update frame of the memory images display view.
        self.memoryImagesDisplayView?.bindFrameToSuperviewBounds()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    //MARK: - Setup
    func setup(withMemory memory: MKMemory) {
        //Set the memory of this cell, along with the memory's data.
        self.memory = memory
        self.songCountLabel.text = "\(memory.items?.count ?? 0) Tracks"
        self.titleLabel.text = memory.title ?? ""
        
        //Dynamic memory setup.
        if memory.isDynamicMemory {
            self.dynamicMemoryLabel.isHidden = false
            self.dynamicMemoryIcon.isHidden = false
            self.dynamicMemoryLabel.textColor = .theme
        }
        else {
            self.dynamicMemoryLabel.isHidden = true
            self.dynamicMemoryIcon.isHidden = true
        }
        
        //Date setup.
        if let startDate = memory.startDate {
            self.dateLabel.isHidden = false
            self.dateLabel.textColor = .secondaryText
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.dateLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
                }
                else {
                    self.dateLabel.text = startDate.medString
                }
            }
            else {
                self.dateLabel.text = startDate.medString
            }
        }
        else {
            self.dateLabel.isHidden = true
        }
        
        //Description setup.
        self.descLabel.text = memory.desc ?? ""
        
        //Set up the images display view.
        if self.memoryImagesDisplayView == nil {
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: self.frame)
            self.image.addSubview(self.memoryImagesDisplayView!)
        }
        
        if self.memoryImagesDisplayView?.memory != memory {
            self.memoryImagesDisplayView?.set(withMemory: memory)
        }
    }
        
    //MARK: - DateIntervalFormatter
    ///Creates and interval string using a start and end date.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
    
    //MARK: - Sizing
    class func size(forCollectionViewWidth collectionViewWidth: CGFloat, andMemory memory: MKMemory) -> CGSize {
        //Calculate the number of items per row.
        let rowItemCount = (collectionViewWidth <= 678.0) ? 1 : (collectionViewWidth <= 981.0) ? 2 : 3

        //Calculate the necessary interitem and margin spacing.
        let horizontalMargins: CGFloat = CGFloat(rowItemCount) * 16.3
        let width = (collectionViewWidth - horizontalMargins) / CGFloat(rowItemCount)
        
        //Calculate the correct height.
        let verticalMargins: CGFloat = 77.0
        let titleHeight: CGFloat = 21.0
        let descriptionHeight: CGFloat = 18.0
        let height = width + verticalMargins + titleHeight + descriptionHeight
        
        return CGSize(width: width, height: height)
    }
}
