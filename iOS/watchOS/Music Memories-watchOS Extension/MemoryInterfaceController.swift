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
        
        //Retrieve the memory in the context.
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
        //Header
        self.titleLabel.setText(memory?.title ?? "No Title")
        self.headerImage.setImage(self.memory?.images?.first?.uiImage)
        
        //Song count label
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
        
        //Send haptic.
        WKInterfaceDevice.current().play(WKHapticType.click)
        //Run the UI.
        let okAction = WKAlertAction(title: "OK", style: .default) {
        }
        self.presentAlert(withTitle: "Playing Memory on iPhone", message: "Your memory \"\(self.memory?.title ?? "")\" is now playing on your iPhone.", preferredStyle: WKAlertControllerStyle.alert, actions: [okAction])

    }
    
    @IBAction func delete() {
        let cancelAction = WKAlertAction(title: "Cancel", style: .cancel) {
            
        }
        let deleteAction = WKAlertAction(title: "Delete", style: .destructive) {
            //Send message to delete it on the user's iPhone.
            self.memory?.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .delete)
            //Delete the memory locally.
            self.memory?.delete()
            
            //Run the haptic.
            WKInterfaceDevice.current().play(WKHapticType.click)
            //Return to the home controller.
            self.pop()
        }
        
        self.presentAlert(withTitle: "Delete Memory", message: "Are you sure you want to delete \"\(self.memory?.title ?? "")\"?", preferredStyle: .sideBySideButtonsAlert, actions: [cancelAction, deleteAction])
    }
        
}
