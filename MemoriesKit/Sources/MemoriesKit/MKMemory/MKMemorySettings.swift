//
//  MKMemorySettings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/27/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

import CoreData

#if os(iOS) || os(tvOS) || os(watchOS)
@available(iOS 11.0, watchOS 3.0, tvOS 10.0, macOS 10.12, *)
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
#endif
