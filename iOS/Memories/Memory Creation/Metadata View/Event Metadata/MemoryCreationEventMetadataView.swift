//
//  MemoryCreationEventMetadataView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 1/28/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import EventKit

///A `MemoryCreationMetadataView` that handles interactions with EventKit.
class MemoryCreationEventMetadataView: MemoryCreationMetadataView {
    ///The event to draw metadata from.
    weak var event: EKEvent?
    
    //MARK: - UIView overrides.
    override func didMoveToSuperview() {
        //super.didMoveToSuperview()
        
        //Preset values from chosen event.
        if let event = self.event {
            self.titleTextView.text = event.title ?? ""
            self.descriptionTextView.text = event.notes ?? ""
        }
    }
}
