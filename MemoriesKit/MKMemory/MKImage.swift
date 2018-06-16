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
    
    //Converts the stored data to a `UIImage` object.
    public func uiImage(withSize size: CGSize = CGSize.square(withSideLength: 250)) -> UIImage? {
        //Retrieve the image data.
        if let data = self.imageData {
            return data.uiImage?.scale(toSize: size)
        }
        return nil
    }
    
    public func set(withUIImage image: UIImage) {
        let data = image.compressedData(withQuality: 1)
        print(data?.sizeInMB ?? 0)
        print("\n\n\n\n\n")
        self.imageData = data
    }
}

//MARK: - Data extension.
public extension Data {
    
    ///Computes the size of this data, in MB.
    public var sizeInMB: Double? {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        let string = bcf.string(fromByteCount: Int64(self.count))
        
        return Double(string.replacingOccurrences(of: " MB", with: ""))
    }
    
    ///Compresses image data, along with rescaling it using a scale factor.
    public func compressForImage(withQuality quality: CGFloat, atNewScale newScale: CGFloat? = nil) -> Data? {
        if let image = UIImage(data: self)?.scale(to: newScale ?? 1) {
            
            return image.compressedData(withQuality: quality)
        }
        return nil
    }
    
    ///Compresses image data, along with resizing it.
    public func compressForImage(withQuality quality: CGFloat, atNewSize newSize: CGSize) -> Data? {
        if let image = UIImage(data: self)?.scale(toSize: newSize) {
            
            return image.compressedData(withQuality: quality)
        }
        return nil
    }
    
    ///Returns a `UIImage` object if this data is for an image.
    public var uiImage: UIImage? {
        return UIImage(data: self)
    }
}

//MARK: - CGSize extension.
public extension CGSize {
    public static func square(withSideLength side: CGFloat) -> CGSize {
        return CGSize(width: side, height: side)
    }
    
    public func scale(to newScale: CGFloat) -> CGSize {
        return CGSize(width: self.width * newScale, height: self.height * newScale)
    }
    
    public var halved: CGSize {
        return self.scale(to: 0.5)
    }
}

//MARK: - UIImage extension.
public extension UIImage {
    ///Returns the compressed data of this image.
    public func compressedData(withQuality quality: CGFloat) -> Data? {
        return UIImageJPEGRepresentation(self, quality)
    }
    
    ///Scales an image to fit within a bounds with a size governed by the passed size. Also keeps the aspect ratio.
    public func scale(toSize newSize: CGSize) -> UIImage? {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = newSize.width / self.size.width
        let aspectheight = newSize.height / self.size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio;
        scaledImageRect.size.height = self.size.height * aspectRatio;
        scaledImageRect.origin.x = (newSize.width - scaledImageRect.size.width) / 2.0;
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0;
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    ///Scales an image using a scale factor.
    public func scale(to newScale: CGFloat) -> UIImage? {
        return self.scale(toSize: self.size.scale(to: newScale))
    }
    
    ///Returns a half scale image.
    public var halfScale: UIImage? {
        return self.scale(toSize: self.size.halved)
    }
}
