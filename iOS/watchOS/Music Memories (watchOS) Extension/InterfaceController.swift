//
//  InterfaceController.swift
//  Music Memories (watchOS) Extension
//
//  Created by Collin DeWaters on 2/7/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import MemoriesKit_watchOS

class InterfaceController: WKInterfaceController {
    
    var memories = Array<Int>()
    
    //MARK: - IBOutlets
    @IBOutlet var noMemoriesImage: WKInterfaceImage!
    @IBOutlet var noMemoriesLabel: WKInterfaceLabel!
    @IBOutlet var createMemoryButton: WKInterfaceButton!
    @IBOutlet var memoriesTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
        //See if we have memories.
        
        if memories.count == 0 {
            self.toggleNoMemoriesUI(toOn: true)
        }
        else {
            self.toggleNoMemoriesUI(toOn: false)
        }
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //MARK: - IBActions
    @IBAction func createMemory() {
        let message = ["MMMessageCode": 100]
        wcSession?.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
    
    //MARK: - UI Hiding
    private func toggleNoMemoriesUI(toOn on: Bool) {
        if on {
            self.memoriesTable.setHidden(true)
            self.noMemoriesImage.setHidden(false)
            self.noMemoriesLabel.setHidden(false)
            self.createMemoryButton.setHidden(false)
            return
        }
        self.memoriesTable.setHidden(false)
        self.noMemoriesImage.setHidden(true)
        self.noMemoriesLabel.setHidden(true)
        self.createMemoryButton.setHidden(true)
    }

}
