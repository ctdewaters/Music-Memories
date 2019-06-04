//
//  MemoryCreationMetadataView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryCreationMetadataView: MemoryCreationView, UITextViewDelegate {
        
    //MARK: - IBOutlets
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var descriptionTextViewTopConstraint: NSLayoutConstraint!
    
    //MARK: - UIView overrides.
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Title text view setup.
        self.titleTextView.textColor = Settings.shared.textColor
        self.titleTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        self.titleTextView.delegate = self
        self.titleTextView.layer.cornerRadius = 10
        self.titleTextView.backgroundColor = Settings.shared.darkMode ? UIColor.black.withAlphaComponent(0.45) : UIColor.white.withAlphaComponent(0.45)
        
        //Description text view setup.
        self.descriptionTextView.textColor = Settings.shared.textColor
        self.descriptionTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        self.descriptionTextView.delegate = self
        self.descriptionTextView.layer.cornerRadius = 10
        self.descriptionTextView.backgroundColor = Settings.shared.darkMode ? UIColor.black.withAlphaComponent(0.45) : UIColor.white.withAlphaComponent(0.45)
        
        //Button setup.
        self.nextButton.setTitleColor(Settings.shared.darkMode ? .black : .white, for: .normal)
        self.nextButton.backgroundColor = Settings.shared.textColor
        self.nextButton.layer.cornerRadius = 10
        
        self.backButton.backgroundColor = Settings.shared.textColor
        self.backButton.addTarget(self, action: #selector(self.back(sender:)), for: .touchUpInside)
        self.backButton.layer.cornerRadius = 10
        self.backButton.tintColor = .theme
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        //Make the title text view the first responder.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.titleTextView.becomeFirstResponder()
        }
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
        
        //Clear fields.
        self.titleTextView.text = ""
        self.descriptionTextView.text = ""

        //Dismiss this view.
        memoryComposeVC?.dismissView()
    }
    
    @IBAction func next(_ sender: Any) {
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
            memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Select a start and end date for this memory (optional). We will use this to find the songs you loved during this period.")
        }
        else if memoryComposeVC?.memory?.sourceType == .calendar {
            memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Add a few photos you remember from this calendar event.")
        }
    }
    
    //MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.titleTextView {
            self.activateDescriptionTextView(textView.text != "")
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            //Return key pressed
            if textView == self.titleTextView && textView.text != "" {
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
    
    //MARK: - Description text view activation.
    func activateDescriptionTextView(_ activate: Bool) {
        //Update constraint constant.
        self.descriptionTextViewTopConstraint.constant = activate ? 16 : 160
                
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: {
            self.layoutIfNeeded()
            
            //Set alphas.
            self.descriptionTextView.alpha = activate ? 1 : 0
        }, completion: nil)
    }
}

//MARK: - MemoryCreationView: Contains a title and subtitle string to display in the header.
class MemoryCreationView: UIView {
    public var title: String?
    
    public var subtitle: String?
}


