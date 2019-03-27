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
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var playOniPhoneButton: WKInterfaceButton!
    @IBOutlet var imageGroup: WKInterfaceGroup!
    
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
        self.imageGroup.setBackgroundImage(self.memory?.images?.first?.uiImage() ?? UIImage(named: "logo500White"))
        
        //Button color.
        self.playOniPhoneButton.setBackgroundColor(.themeColor)
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
}
