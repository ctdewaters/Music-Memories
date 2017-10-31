//
//  MemorySettingsActionView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/31/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemorySettingsActionView: UIView {
    
    static let requiredHeight: CGFloat = (60 * 3) + (8 * 2)

    //MARK: - IBOutlets
    @IBOutlet weak var cancelBackground: UIVisualEffectView!
    @IBOutlet weak var editBackground: UIVisualEffectView!
    @IBOutlet weak var deleteBackground: UIVisualEffectView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    ///MARK: - Callbacks
    var cancelCallback: (()->Void)?
    var editCallback: (()->Void)?
    var deleteCallback: (()->Void)?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Set button corner radii
        let radii: CGFloat = 15
        self.cancelBackground.layer.cornerRadius = radii
        self.editBackground.layer.cornerRadius = radii
        self.deleteBackground.layer.cornerRadius = radii
    }
    
    //MARK: - Presentation and dismissal
    func present(toPoint point: CGPoint) {
        //Prepare.
        self.center.y += MemorySettingsActionView.requiredHeight + 20
        self.alpha = 0
        
        UIView.animate(withDuration: 0.2) {
            self.center = point
            self.alpha = 1
        }
    }
    
    func dismiss(withCompletion completion: (()->Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.center.y += MemorySettingsActionView.requiredHeight + 20
            self.alpha = 0
        }, completion: { (completed) in
            if completed {
                self.removeFromSuperview()
                completion?()
            }
        })
    }

    
    @IBAction func buttonPressed(_ sender: Any) {
        if let sender = sender as? UIButton {
            if sender == cancelButton {
                self.cancelCallback?()
            }
            else if sender == editButton {
                self.editCallback?()
            }
            else if sender == deleteButton {
                self.deleteCallback?()
            }
        }
    }
    
    
}
