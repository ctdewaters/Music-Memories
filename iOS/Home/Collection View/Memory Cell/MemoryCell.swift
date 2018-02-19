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

class MemoryCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var infoBlur: UIVisualEffectView!
    @IBOutlet weak var songCountBlur: UIVisualEffectView!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoBlurHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dynamicMemoryBlur: UIVisualEffectView!
    @IBOutlet weak var dynamicMemoryImage: UIImageView!
    
    //MARK: - Visual state
    enum State {
        case dark, light
    }
    
    var state: State {
        set {
            if newValue == .light {
                self.songCountBlur.effect = UIBlurEffect(style: .extraLight)
                self.dynamicMemoryBlur.effect = UIBlurEffect(style: .extraLight)
                self.infoBlur.effect = UIBlurEffect(style: .extraLight)
                self.songCountLabel.textColor = .black
                self.dateLabel.textColor = .black
                self.titleLabel.textColor = .black
                return
            }
            self.songCountBlur.effect = UIBlurEffect(style: .dark)
            self.dynamicMemoryBlur.effect = UIBlurEffect(style: .dark)
            self.infoBlur.effect = UIBlurEffect(style: .dark)
            self.songCountLabel.textColor = .white
            self.dateLabel.textColor = .white
            self.titleLabel.textColor = .white
        }
        get {
            if self.songCountBlur.effect == UIBlurEffect(style: .extraLight) {
                return .light
            }
            return .dark
        }
    }
    
    ///The index path of this cell.
    var indexPath: IndexPath!
    
    ///Reference to associated memory.
    weak var memory: MKMemory?
    
    ///The image viewer that will display the images for this memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        //Set corner radius.
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
        self.songCountBlur.layer.cornerRadius = self.songCountBlur.frame.width / 2
        
        self.dynamicMemoryBlur.layer.cornerRadius = self.songCountBlur.frame.width / 2
        self.dynamicMemoryImage.tintColor = .themeColor
        
        self.image.backgroundColor = .darkGray
        
        //Update frame of the memory images display view.
        self.memoryImagesDisplayView?.bindFrameToSuperviewBounds()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    
    //MARK: - Setup
    func setup(withMemory memory: MKMemory) {
        self.memory = memory
        self.songCountLabel.text = "\(memory.items?.count ?? 0)"
        self.titleLabel.text = memory.title ?? "Unnamed Memory"
        
        //Dynamic memory setup.
        if memory.isDynamicMemory {
            self.dynamicMemoryBlur.isHidden = false
        }
        else {
            self.dynamicMemoryBlur.isHidden = true
        }
        
        //Date setup.
        if let startDate = memory.startDate {
            self.dateLabel.isHidden = false
            self.dateLabel.textColor = Settings.shared.accessoryTextColor
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.dateLabel.text = "\(startDate.shortString) • \(endDate.shortString)"
                }
                else {
                    self.dateLabel.text = startDate.shortString
                }
            }
            else {
                self.dateLabel.text = startDate.shortString
            }
        }
        else {
            self.dateLabel.isHidden = true
        }
        
        //Set up the images display view.
        if self.memoryImagesDisplayView == nil {
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: self.frame)
            self.image.addSubview(self.memoryImagesDisplayView!)
        }
        if self.memoryImagesDisplayView?.memory != memory {
            self.memoryImagesDisplayView?.set(withMemory: memory)
        }
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.image.alpha = 0.7
        }
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.image.alpha = 1
        }
    }
}
