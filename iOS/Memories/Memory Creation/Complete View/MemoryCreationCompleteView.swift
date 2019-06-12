//
//  MemoryCreationCompleteView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/26/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryCreationCompleteView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var successCheckmarkHoldingView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var syncSettingLabel: UILabel!
    @IBOutlet weak var syncSwitch: UISwitch!
    
    var successCheckmark: CDHUDSuccessCheckmark!
    
    //MARK: - Overrides
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Add the checkmark to the view, and animate it.
        self.addCheckmarkToView()
        self.successCheckmark.animate(withDuration: 2)
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = .label
                button.layer.cornerRadius = 10
            }
        }
        self.closeButton.setTitleColor(.systemBackground, for: .normal)
        
        //Switch setup.
        self.syncSwitch.onTintColor = .theme
        self.syncSettingLabel.textColor = .label
    }
    
    func addCheckmarkToView() {
        self.successCheckmark = CDHUDSuccessCheckmark(withFrame: self.successCheckmarkHoldingView.bounds, andTintColor: .theme, andLineWidth: 20, withOutlineCircle: true)
        self.successCheckmarkHoldingView.layer.addSublayer(self.successCheckmark)
    }
    
    //MARK: - IBActions
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        memoryComposeVC?.memory?.settings?.updateWithAppleMusic = sender.isOn
    }
    
    @IBAction func close(_ sender: Any) {
        //Send the memory to the watch.
        memoryComposeVC?.memory?.addToUserInfoQueue(withSession: wcSession, withTransferSetting: .update)
        
        //Schedule the memory's reminder notification.
        if let content = memoryComposeVC?.memory?.notificationContent, let sendDate = Date().add(days: 1, months: 0, years: 0) {
            AppDelegate.schedule(localNotificationWithContent: content, withIdentifier: memoryComposeVC?.memory?.storageID ?? "memoryReminder", andSendDate: sendDate)
        }
        
        //Present the CDHUD if the sync switch is on.
        if self.syncSwitch.isOn {
            let content = CDHUD.ContentType.processing(title: "Syncing Memory to Apple Music...")
            CDHUD.shared.present(animated: true, withContentType: content, toView: memoryComposeVC!.view)
        }
        
        //Sync to the user library (this will fall through if the user disabled the feature).
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.syncSwitch.isOn ? 0.25 : 0)) {            
            memoryComposeVC?.memory?.syncToUserLibrary {
                DispatchQueue.main.async {
                    //Dismiss CDHUD.
                    CDHUD.shared.dismiss(animated: true, afterDelay: 0)
                    //Delete the local reference to the memory, and go home.
                    DispatchQueue.main.asyncAfter(deadline: .now() + (self.syncSwitch.isOn ? 0.25 : 0)) {
                        memoryComposeVC?.memory = nil
                        memoryComposeVC?.goHome(self)
                    }
                }
            }
        }
    }
}
