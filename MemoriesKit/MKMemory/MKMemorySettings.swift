//
//  MKMemorySettings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/27/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import CoreData

public class MKMemorySettings: NSManagedObject {
    
    ///Determines whether or not to update (or create) a playlist in the user's Apple Music library.
    @NSManaged public var syncWithAppleMusicLibrary: NSNumber!
    
    ///The associated MKMemory object.
    @NSManaged public var memory: MKMemory?
    
    public var updateWithAppleMusic: Bool {
        set {
            self.syncWithAppleMusicLibrary = NSNumber(value: newValue)
            self.memory?.save()
        }
        get {
            return self.syncWithAppleMusicLibrary.boolValue
        }
    }

}
