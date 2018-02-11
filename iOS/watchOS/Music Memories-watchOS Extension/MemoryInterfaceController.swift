//
//  MemoryInterfaceController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import WatchKit
import MemoriesKit_watchOS

class MemoryInterfaceController: WKInterfaceController {
    
    //MARK: - IBOutlets.
    @IBOutlet var headerGroup: WKInterfaceGroup!
    @IBOutlet var headerImage: WKInterfaceImage!
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var songCountLabel: WKInterfaceLabel!
    @IBOutlet var separator: WKInterfaceSeparator!
    @IBOutlet var playOniPhoneButton: WKInterfaceButton!
    @IBOutlet var deleteButton: WKInterfaceButton!
    
    //MARK: - Properties.
    var memory: MKMemory?
    
    //MARK: - WKInterfaceController overrides.
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        if let memory = context as? MKMemory {
            self.memory = memory
            self.setup()
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

    //MARK: - Setup.
    func setup() {
        self.titleLabel.setText(memory?.title ?? "No Title")
        
        if memory?.items?.count == 1 {
            self.songCountLabel.setText("1 Song")
        }
        else {
            self.songCountLabel.setText("\(memory?.items?.count ?? 0) Songs")
        }
    }
    
    //MARK: - IBActions.
    @IBAction func playOniPhone() {
        memory?.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .playback)
    }
    
    @IBAction func delete() {
        //Delete the memory locally.
        memory?.delete()
        
        //Send message to delete it on the user's iPhone.
        memory?.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .delete)

        //Return to the home controller.
        self.pop()
    }
    
    
}
