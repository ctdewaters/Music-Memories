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

    ///The binary image data.
    @NSManaged public var imageData: Data?
    
    ///The associated memory.
    @NSManaged public var memory: MKMemory?
    
    ///A storage ID used on the MM server.
    @NSManaged public var storageID: String?
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        guard let moc = self.managedObjectContext else { return }
              
        moc.perform {
            //Set storage ID if it has not already been set.
            if self.storageID == nil {
                self.storageID = String.random(withLength: 50)
                self.save()
                print("SAVED IMAGE WITH STORAGE ID \(self.storageID ?? "")")
            }
        }
    }
        
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
    
    //MARK: - Saving and Deleting.
    ///Deletes this image from Core Data.
    public func delete() {
        self.managedObjectContext?.delete(self)
        self.save()
    }
    
    ///Saves the context.
    public func save() {
        guard let moc = self.managedObjectContext else { return }
        MKCoreData.shared.save(context: moc)
    }
}

//MARK: - Data extension.
public extension Data {
    
    ///Computes the size of this data, in MB.
    var sizeInMB: Double? {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB]
        bcf.countStyle = .file
        let string = bcf.string(fromByteCount: Int64(self.count))
        
        return Double(string.replacingOccurrences(of: " MB", with: ""))
    }
    
    ///Compresses image data, along with rescaling it using a scale factor.
    func compressForImage(withQuality quality: CGFloat, atNewScale newScale: CGFloat? = nil) -> Data? {
        if let image = UIImage(data: self)?.scale(to: newScale ?? 1) {
            
            return image.compressedData(withQuality: quality)
        }
        return nil
    }
    
    ///Compresses image data, along with resizing it.
    func compressForImage(withQuality quality: CGFloat, atNewSize newSize: CGSize) -> Data? {
        if let image = UIImage(data: self)?.scale(toSize: newSize) {
            
            return image.compressedData(withQuality: quality)
        }
        return nil
    }
    
    ///Returns a `UIImage` object if this data is for an image.
    var uiImage: UIImage? {
        return UIImage(data: self)
    }
}

//MARK: - CGSize extension.
public extension CGSize {
    static func square(withSideLength side: CGFloat) -> CGSize {
        return CGSize(width: side, height: side)
    }
    
    func scale(to newScale: CGFloat) -> CGSize {
        return CGSize(width: self.width * newScale, height: self.height * newScale)
    }
    
    var halved: CGSize {
        return self.scale(to: 0.5)
    }
}

//MARK: - UIImage extension.
public extension UIImage {
    ///Returns the compressed data of this image.
    func compressedData(withQuality quality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
    ///Scales an image to fit within a bounds with a size governed by the passed size. Also keeps the aspect ratio.
    func scale(toSize newSize: CGSize) -> UIImage? {
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
    func scale(to newScale: CGFloat) -> UIImage? {
        return self.scale(toSize: self.size.scale(to: newScale))
    }
    
    ///Returns a half scale image.
    var halfScale: UIImage? {
        return self.scale(toSize: self.size.halved)
    }
}
