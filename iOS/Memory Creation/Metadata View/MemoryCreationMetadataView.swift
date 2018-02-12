//
//  MemoryCreationMetadataView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import UITextView_Placeholder

class MemoryCreationMetadataView: MemoryCreationView, UITextViewDelegate {
        
    //MARK: - IBOutlets
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var titleViewSeparator: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionViewSeparator: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    //MARK: - UIView overrides.
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Title text view setup.
        self.titleTextView.textColor = Settings.shared.textColor
        self.titleTextView.placeholderColor = Settings.shared.accessoryTextColor.withAlphaComponent(0.8)
        self.titleTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        self.titleTextView.delegate = self
        
        //Description text view setup.
        self.descriptionTextView.textColor = Settings.shared.textColor
        self.descriptionTextView.placeholderColor = Settings.shared.accessoryTextColor
        self.descriptionTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        self.descriptionTextView.delegate = self
        
        //Separator setup.
        self.titleViewSeparator.backgroundColor = Settings.shared.textColor
        self.descriptionViewSeparator.backgroundColor = Settings.shared.textColor
        self.titleViewSeparator.layer.cornerRadius = 0.5
        self.descriptionTextView.layer.cornerRadius = 0.5
        
        //Button setup.
        self.nextButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        self.nextButton.backgroundColor = Settings.shared.textColor
        self.nextButton.layer.cornerRadius = 10
        
        self.backButton.backgroundColor = Settings.shared.textColor
        self.backButton.addTarget(self, action: #selector(self.back(sender:)), for: .touchUpInside)
        self.backButton.layer.cornerRadius = 10
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        //Resign first responder of all views.
        for view in self.subviews {
            view.resignFirstResponder()
        }
    }
    
    //MARK: - IBActions.
    @objc func back(sender: UIButton) {
        //Resign first responder of all views.
        for view in self.subviews {
            view.resignFirstResponder()
        }

        //Dismiss this view.
        memoryComposeVC?.dismissView()
    }
    
    @IBAction func next(_ sender: Any) {
        
        print("FUCK")
        //Check if user entered a title.
        if self.titleTextView.text == "" {
            //No title entered, display the error HUD.
            let contentType = CDHUD.ContentType.error(title: "You must add a title!")
            CDHUD.shared.contentTintColor = .red
            CDHUD.shared.present(animated: true, withContentType: contentType, toView: memoryComposeVC!.view, removeAfterDelay: 1.5)
            return
        }
        
        //Set the memory's title and description properties.
        memoryComposeVC?.memory?.title = self.titleTextView.text
        memoryComposeVC?.memory?.desc = self.descriptionTextView.text
        
        //Resign first responder of all views.
        for view in self.subviews {
            view.resignFirstResponder()
        }
        
        //Present the next view.
        if memoryComposeVC?.memory?.sourceType == .past {
            memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Select a start and end date for this memory (optional).")
        }
        else if memoryComposeVC?.memory?.sourceType == .calendar {
            memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Add a few photos you remember from this calendar event.")
        }
    }
    
    //MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //Return key pressed
            if textView == self.titleTextView {
                self.descriptionTextView.becomeFirstResponder()
            }
            else {
                //Continue.
                self.next(self)
            }
            return false
        }
        return true
    }
}

//MARK: - MemoryCreationView: Contains a title and subtitle string to display in the header.
class MemoryCreationView: UIView {
    public var title: String?
    
    public var subtitle: String?
}


