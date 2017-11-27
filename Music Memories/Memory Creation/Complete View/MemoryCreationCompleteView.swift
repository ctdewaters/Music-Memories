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
    
    var successCheckmark: CDHUDSuccessCheckmark!
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        memoryComposeVC?.memory = nil
        
        //Add the checkmark to the view, and animate it.
        self.addCheckmarkToView()
        self.successCheckmark.animate(withDuration: 1.25)
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.textColor
                button.layer.cornerRadius = 10
            }
        }
        self.closeButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        
    }
    
    func addCheckmarkToView() {
        self.successCheckmark = CDHUDSuccessCheckmark(withFrame: self.successCheckmarkHoldingView.bounds, andTintColor: .themeColor, andLineWidth: 20, withOutlineCircle: true)
        self.successCheckmarkHoldingView.layer.addSublayer(self.successCheckmark)
    }
    
    @IBAction func close(_ sender: Any) {
        memoryComposeVC?.goHome(self)
    }
}
