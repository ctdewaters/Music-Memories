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

///Reference to the home interface controller.
var homeIC: HomeInterfaceController?

///Array of id's for memories with pending image transfers.
var pendingImageTransferIDs = [String]()

class HomeInterfaceController: WKInterfaceController {
    
    var memories = [MKMemory]()
    
    //MARK: - IBOutlets
    @IBOutlet var noMemoriesImage: WKInterfaceImage!
    @IBOutlet var noMemoriesLabel: WKInterfaceLabel!
    @IBOutlet var createMemoryButton: WKInterfaceButton!
    @IBOutlet var memoriesTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        //Set global variable.
        homeIC = self
    }
    
    override func willActivate() {
        super.willActivate()
        
        //Reload.
        self.reload()
    }
    
    override func didAppear() {
        super.didAppear()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //MARK: - IBActions
    @IBAction func createMemory() {
        //Send message.
        let message = ["MMMessageCode": 100]
        wcSession?.sendMessage(message, replyHandler: nil, errorHandler: nil)

        //Show prompt.
        let okAction = WKAlertAction(title: "OK", style: .default) {
        }
        self.presentAlert(withTitle: "Create a Memory on iPhone", message: "Your memories will appear here once you create them.", preferredStyle: .alert, actions: [okAction])
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
            self.toggleTable(toOn: true)
            
            //Setup table
            self.setupTable()
        }
    }
    
    //MARK: - Table.
    ///Sets up the table.
    func setupTable() {
        //Prepare the images.
        
        self.memoriesTable.setNumberOfRows(self.memories.count, withRowType: "MemoryTableRowController")
        
        for i in 0..<self.memories.count {
            let rowController = self.memoriesTable.rowController(at: i) as! MemoryTableRowController
            rowController.titleLabel.setText(self.memories[i].title ?? "No Title")
            rowController.itemCountLabel.setText("\(self.memories[i].items?.count ?? 0)")
            
            //Set image.
            if let mkImage = self.memories[i].images?.first {
                rowController.backgroundGroup.setBackgroundImage(mkImage.uiImage)
            }
            else if !pendingImageTransferIDs.contains(self.memories[i].storageID ?? ""){
                //Signal for phone to transfer image.
                self.memories[i].messageToCompanionDevice(withSession: wcSession, withTransferSetting: .requestImage)
                
                //Add memory id to the pending transfer id array.
                pendingImageTransferIDs.append(self.memories[i].storageID ?? "")
            }
        }
    }

    ///Handles table selection.
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        //Push to the memory controller with the memories context.
        self.pushController(withName: "memoryIC", context: memories[rowIndex])
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
            self.memoriesTable.setHidden(false)
            return
        }
        self.memoriesTable.setHidden(true)
    }
    
}

//MARK: - Table Row Controller
class MemoryTableRowController: NSObject {
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var itemCountLabel: WKInterfaceLabel!
    @IBOutlet var backgroundGroup: WKInterfaceGroup!
    @IBOutlet var infoGroup: WKInterfaceGroup!
}

