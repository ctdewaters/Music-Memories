//
//  MemoryCreationMetadataView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import UITextView_Placeholder

class MemoryCreationMetadataView: MemoryCreationView {
        
    //MARK: - IBOutlets
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var titleViewSeparator: UIView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionViewSeparator: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        //Title text view setup.
        self.titleTextView.textColor = Settings.shared.textColor
        self.titleTextView.placeholderColor = Settings.shared.accessoryTextColor.withAlphaComponent(0.8)
        self.titleTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        
        //Description text view setup.
        self.descriptionTextView.textColor = Settings.shared.textColor
        self.descriptionTextView.placeholderColor = Settings.shared.accessoryTextColor
        self.descriptionTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        
        //Separator setup.
        self.titleViewSeparator.backgroundColor = Settings.shared.textColor
        self.descriptionViewSeparator.backgroundColor = Settings.shared.textColor
        
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
        
        for view in self.subviews {
            view.resignFirstResponder()
        }
    }
    
    @objc func back(sender: UIButton) {
        memoryComposeVC.dismissView()
        
        let titleView = MemoryCreationView()
        titleView.title = "Create a Memory"
        titleView.subtitle = "What kind of memory do you want to create?"
        memoryComposeVC.updateHeader(withView: titleView)
    }
    
    @IBAction func next(_ sender: Any) {
        print("NEXT")
        memoryComposeVC.pastMemoryRoute[1].title = self.title
        memoryComposeVC.pastMemoryRoute[1].subtitle = "Select a start and end date for this memory (optional)."
        memoryComposeVC.present(view: memoryComposeVC.pastMemoryRoute[1])
    }
}

//MARK: - MemoryCreationView: Contains a title and subtitle string to display in the header.
class MemoryCreationView: UIView {
    public var title: String?
    
    public var subtitle: String?
}


