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
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        self.titleTextView.textColor = Settings.shared.textColor
        self.titleTextView.placeholderColor = Settings.shared.accessoryTextColor.withAlphaComponent(0.8)
        self.titleTextView.keyboardAppearance = Settings.shared.keyboardAppearance
        
        
        self.titleViewSeparator.backgroundColor = Settings.shared.textColor
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
}

//MARK: - MemoryCreationView: Contains a title and subtitle string to display in the header.
class MemoryCreationView: UIView {
    public var title: String?
    
    public var subtitle: String?
}


