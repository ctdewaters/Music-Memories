
//
//  MemoryCreationCompleteViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MarqueeLabel
import CoreData

/// `MemoryCreationCompleteViewController`: Displays UI for the memory that has just been created, and allows the user to add to their music library.
class MemoryCreationCompleteViewController: UIViewController {
    
    //MARK: IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var memoryView: UIView!
    @IBOutlet weak var imagesDisplayHoldingView: UIView!
    @IBOutlet weak var memoryTitleLabel: MarqueeLabel!
    @IBOutlet weak var memoryDatesLabel: UILabel!
    @IBOutlet weak var memoryTrackCountLabel: UILabel!
    @IBOutlet weak var memoryViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var addToAppleMusicLabel: UILabel!
    @IBOutlet weak var addToAppleMusicSwitch: UISwitch!
    
    //MARK: Properties
    var imagesDisplayView: MemoryImagesDisplayView!
    
    ///The newly created memory object ID.
    var memoryObjectID: NSManagedObjectID?
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for view in self.view.subviews {
            view.alpha = 0
        }
        
        self.memoryView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        
        self.createMKMemory()
    }
    
    //MARK: MKMemory Creation
    /// Creates a new `MKMemory` object with the user provided data.
    func createMKMemory() {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        
        moc.perform {
            let memory = MKCoreData.shared.createNewMKMemory(inContext: moc)
            memory.title = MemoryCreationData.shared.name
            memory.desc = MemoryCreationData.shared.desc
            memory.startDate = MemoryCreationData.shared.startDate
            memory.endDate = MemoryCreationData.shared.endDate
            memory.settings?.syncWithAppleMusicLibrary = NSNumber(booleanLiteral: false)
            
            //Add media items.
            if let mediaItems = MemoryCreationData.shared.mediaItems {
                for item in mediaItems {
                    memory.add(mpMediaItem: item)
                }
            }
            
            //Add images.
            if let images = MemoryCreationData.shared.images {
                for image in images {
                    let mkImage = MKCoreData.shared.createNewMKImage(inContext: moc)
                    mkImage.set(withUIImage: image)
                    mkImage.memory = memory
                }
            }
            
            memory.save(sync: true, withAPNS: true) {
                //Upload images
                guard let images = memory.images else { return }
                for image in images {
                    MKCloudManager.upload(mkImage: image)
                }
            }
                        
            self.memoryObjectID = memory.objectID
                        
            DispatchQueue.main.async {
                memoriesViewController?.reload()
                self.activateMemoryView(withMemory: memory)
            }
        }
    }
    
    //MARK: Memory View Functions
    func activateMemoryView(withMemory memory: MKMemory) {
        //Setup the memory view.
        self.setupMemoryView(withMemory: memory)

        //Present the view.
        self.memoryViewTopConstraint.constant = 30
        
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
            for view in self.view.subviews {
                view.alpha = 1
            }
            self.memoryView.transform = .identity
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func setupMemoryView(withMemory memory: MKMemory) {
        //Set info in view.
        self.setupImagesDisplayView(withMemory: memory)
        self.memoryTitleLabel.text = memory.title ?? ""
        self.memoryTrackCountLabel.text = "\(memory.items?.count ?? 0) Songs"
        
        //Date setup.
        if let startDate = memory.startDate {
            self.memoryDatesLabel.isHidden = false
            self.memoryDatesLabel.textColor = .secondaryText
            if let endDate = memory.endDate {
                if startDate.yesterday != endDate.yesterday {
                    self.memoryDatesLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
                }
                else {
                    self.memoryDatesLabel.text = startDate.medString
                }
            }
            else {
                self.memoryDatesLabel.text = startDate.medString
            }
        }
        else {
            self.memoryDatesLabel.isHidden = true
        }
    }
    
    func setupImagesDisplayView(withMemory memory: MKMemory) {
        self.imagesDisplayView = MemoryImagesDisplayView(frame: self.imagesDisplayHoldingView.frame)
        self.imagesDisplayHoldingView.addSubview(self.imagesDisplayView)
        self.imagesDisplayView.bindFrameToSuperviewBounds()
        self.imagesDisplayView.set(withMemory: memory)
    }
    
    //MARK: IBActions
    @IBAction func close(_ sender: Any) {
        self.handleLibrarySync()
        
        UIWindow.key?.rootViewController?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Library Syncing
    private func handleLibrarySync() {
        
        if self.addToAppleMusicSwitch.isOn {
            
            let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            moc.parent = MKCoreData.shared.managedObjectContext
            guard let objectID = self.memoryObjectID, let memory = moc.object(with: objectID) as? MKMemory else { return }
            
            moc.perform {
                memory.settings?.updateWithAppleMusic = true
                memory.syncToUserLibrary()
            }
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
}
