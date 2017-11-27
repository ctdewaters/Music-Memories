//
//  MemoryCreationCompleteView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/26/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryCreationCompleteView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var successCheckmarkHoldingView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var syncSettingLabel: UILabel!
    @IBOutlet weak var syncSwitch: UISwitch!
    
    var successCheckmark: CDHUDSuccessCheckmark!
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Add the checkmark to the view, and animate it.
        self.addCheckmarkToView()
        self.successCheckmark.animate(withDuration: 2)
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.textColor
                button.layer.cornerRadius = 10
            }
        }
        self.closeButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        
        //Switch setup.
        self.syncSwitch.onTintColor = .themeColor
        self.syncSettingLabel.textColor = Settings.shared.textColor
    }
    
    func addCheckmarkToView() {
        self.successCheckmark = CDHUDSuccessCheckmark(withFrame: self.successCheckmarkHoldingView.bounds, andTintColor: .themeColor, andLineWidth: 20, withOutlineCircle: true)
        self.successCheckmarkHoldingView.layer.addSublayer(self.successCheckmark)
    }
    
    //MARK: - IBActions
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        memoryComposeVC?.memory?.settings?.updateWithAppleMusic = sender.isOn
    }
    
    @IBAction func close(_ sender: Any) {
        memoryComposeVC?.memory?.syncToUserLibrary()
        memoryComposeVC?.memory = nil
        memoryComposeVC?.goHome(self)
    }
}
