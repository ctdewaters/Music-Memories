//
//  MemoryCreationTitleViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/15/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryCreationTitleViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var titleField: UITextView!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var nextButton: UIButton!
    
    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        //Text view setup.
        for subview in self.view.subviews {
            if let textView = subview as? UITextView {
                textView.cornerRadius = 10
                textView.textContainerInset.bottom = 20
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

}
