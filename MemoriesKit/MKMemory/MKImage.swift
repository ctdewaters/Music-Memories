//
//  MKImage.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class MKImage: NSManagedObject {

    @NSManaged public var imageData: Data?
    
    @NSManaged public var memory: MKMemory?
    
    public var uiImage: UIImage? {
        if let data = self.imageData {
            return UIImage(data: data)
        }
        return nil
    }
    
    public func set(withUIImage image: UIImage) {
        let data = UIImageJPEGRepresentation(image, 1)
        self.imageData = data
    }
}
