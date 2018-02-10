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

var mainIC: InterfaceController?

class InterfaceController: WKInterfaceController {
    
    var memories = [MKMemory]()
    
    //MARK: - IBOutlets
    @IBOutlet var noMemoriesImage: WKInterfaceImage!
    @IBOutlet var noMemoriesLabel: WKInterfaceLabel!
    @IBOutlet var createMemoryButton: WKInterfaceButton!
    @IBOutlet var memoriesTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)        
        //Set global variable.
        mainIC = self
        
        //Reload
        self.reload()
        
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
    
    //MARK: - Reloading.
    @IBAction @objc func reload() {
        self.memories = MKCoreData.shared.fetchAllMemories()

        if memories.count == 0 {
            self.toggleNoMemoriesUI(toOn: true)
            self.toggleTable(toOn: false)
        }
        else {
            self.toggleNoMemoriesUI(toOn: false)
            self.toggleTable(toOn: false)
            
            //Setup table
            self.setupTable()
        }
    }
    
    //MARK: - Table Setup.
    func setupTable() {
        self.memoriesTable.setNumberOfRows(self.memories.count, withRowType: "MemoryTableRowController")
        
        for i in 0..<self.memories.count {
            let rowController = self.memoriesTable.rowController(at: i) as! MemoryTableRowController
            rowController.titleLabel.setText(self.memories[i].title ?? "No Title")
            rowController.itemCountLabel.setText("\(self.memories[i].items?.count ?? 0)")
            
        }
    }
    
    //MARK: - UI Hiding
    private func toggleNoMemoriesUI(toOn on: Bool) {
        if on {
            self.noMemoriesImage.setHidden(false)
            self.noMemoriesLabel.setHidden(false)
            self.createMemoryButton.setHidden(false)
            return
        }
        self.noMemoriesImage.setHidden(true)
        self.noMemoriesLabel.setHidden(true)
        self.createMemoryButton.setHidden(true)
    }
    
    private func toggleTable(toOn on: Bool) {
        if on {
            self.memoriesTable.setHidden(true)
            return
        }
        self.memoriesTable.setHidden(false)
    }

}

//MARK: - Table Row Controller
class MemoryTableRowController: NSObject {
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var itemCountLabel: WKInterfaceLabel!
}
