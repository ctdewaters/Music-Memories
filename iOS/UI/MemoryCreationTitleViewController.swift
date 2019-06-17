//
//  MemoryCreationTitleViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/15/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

///`MemoryCreationTitleViewController`: First memory creation view controller, allows user to select a title and description for a memory.
class MemoryCreationTitleViewController: UIViewController, UITextViewDelegate {

    //MARK: IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleField: UITextView!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var titleFieldLabel: UILabel!
    @IBOutlet weak var descriptionFieldLabel: UILabel!
    @IBOutlet weak var descriptionFieldTopConstraint: NSLayoutConstraint!
    
    //MARK: Properties
    ///The data object to store the generate data in.
    var data: MemoryCreationData?
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.data = MemoryCreationData()

        //Text view setup.
        for subview in self.view.subviews {
            if let textView = subview as? UITextView {
                textView.cornerRadius = 10
                textView.textContainerInset.bottom = 20
                textView.textContainerInset.left = 8
                textView.textContainerInset.right = 8
                textView.delegate = self
            }
        }
        
        self.nextButton.frame.size = CGSize.square(withSideLength: 30)
        self.nextButton.cornerRadius = 15
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.titleField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Resign first responder for subviews.
        for subview in self.view.subviews {
            subview.resignFirstResponder()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        //Resign first responder for subviews.
        for subview in self.view.subviews {
            subview.resignFirstResponder()
        }
    }
    
    //MARK: UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.titleField {
            self.activateDescriptionTextView(textView.text != "")
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //Return key pressed
            if textView == self.titleField && textView.text != "" {
                self.descriptionField.becomeFirstResponder()
            }
            else {
                //Continue.
                //self.next(self)
            }
            return false
        }
        return true
    }
    
    //MARK: - Description Text View Activation
    func activateDescriptionTextView(_ activate: Bool) {
        self.descriptionFieldTopConstraint.constant = activate ? 16 : 160
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            
            //Set alphas.
            self.descriptionField.alpha = activate ? 1 : 0
            self.descriptionFieldLabel.alpha = activate ? 1 : 0
        }, completion: nil)
    }

}

//MARK: - MemoryCreationMetadata
///`MemoryCreationData`: Contains data obtained during the memory creation process.
struct MemoryCreationData {
    var name: String?
    var desc: String?
    var startDate: Date?
    var endDate: Date?
    var mediaItems: [MPMediaItem]?
    var images: [UIImage]?
}
