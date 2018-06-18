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
    @IBOutlet weak var infoBlurBackgroundView: UIView!
    @IBOutlet weak var songCountBlurBackgroundView: UIView!
    @IBOutlet weak var dynamicMemoryBackgroundView: UIView!
    
    //MARK: - Visual state
    enum State {
        case dark, light
    }
    
    var state: State {
        set {
            if newValue == .light {
                self.songCountBlur.effect = UIBlurEffect(style: .light)
                self.dynamicMemoryBlur.effect = UIBlurEffect(style: .light)
                self.infoBlur.effect = UIBlurEffect(style: .light)
                self.songCountLabel.textColor = .white
                self.dateLabel.textColor = .white
                self.titleLabel.textColor = .white
                self.infoBlurBackgroundView.isHidden = false
                self.songCountBlurBackgroundView.isHidden = false
                if self.memory?.isDynamicMemory ?? false {
                    self.dynamicMemoryBackgroundView.isHidden = false
                }
                return
            }
            self.songCountBlur.effect = UIBlurEffect(style: .dark)
            self.dynamicMemoryBlur.effect = UIBlurEffect(style: .dark)
            self.infoBlur.effect = UIBlurEffect(style: .dark)
            self.songCountLabel.textColor = .white
            self.dateLabel.textColor = .white
            self.titleLabel.textColor = .white
            self.infoBlurBackgroundView.isHidden = true
            self.songCountBlurBackgroundView.isHidden = true
            self.dynamicMemoryBackgroundView.isHidden = true
        }
        get {
            if self.songCountBlur.effect == UIBlurEffect(style: .light) {
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
        self.layer.cornerRadius = 25
        self.clipsToBounds = true
        
        self.songCountBlur.layer.cornerRadius = self.songCountBlur.frame.width / 2
        self.songCountBlurBackgroundView.layer.cornerRadius = self.songCountBlurBackgroundView.frame.width / 2
        
        self.dynamicMemoryBlur.layer.cornerRadius = self.dynamicMemoryBlur.frame.width / 2
        self.dynamicMemoryBackgroundView.layer.cornerRadius = self.dynamicMemoryBackgroundView.frame.width / 2
        
        self.dynamicMemoryImage.tintColor = .themeColor
        
        self.image.backgroundColor = .lightGray
        
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
            self.dynamicMemoryBackgroundView.isHidden = false
        }
        else {
            self.dynamicMemoryBlur.isHidden = true
            self.dynamicMemoryBackgroundView.isHidden = true
        }
        
        //Date setup.
        if let startDate = memory.startDate {
            self.dateLabel.isHidden = false
            self.dateLabel.textColor = Settings.shared.accessoryTextColor
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.dateLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
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
        self.memoryImagesDisplayView?.set(withMemory: memory)
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.05, delay: 0, options: .curveEaseOut, animations: {
            self.alpha = 0.7
        }, completion: nil)
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.05) {
            self.alpha = 1
        }
    }
    
    //MARK: - DateIntervalFormatter.
    ///Creates and interval string using a start and end date.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
}
