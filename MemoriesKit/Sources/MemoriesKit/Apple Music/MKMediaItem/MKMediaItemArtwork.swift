//
//  MKMediaItemArtwork.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/16/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
@available(iOS 11.0, *)
public class MKMediaItemArtwork {
    
    // MARK: Types
    /// The various keys needed for serializing an instance of `MKMediaItemArtwork` using a JSON response from the Apple Music Web Service.
    struct JSONKeys {
        static let height = "height"
        
        static let width = "width"
        
        static let url = "url"
    }
    
    // MARK: Properties
    /// The maximum height available for the image.
    public let height: Int
    
    /// The maximum width available for the image.
    public let width: Int
    
    /**
     The string representation of the URL to request the image asset. This template should be used to create the URL for the correctly sized image
     your application wishes to use.  See `Artwork.imageURL(size:)` for additional information.
     */
    public let urlTemplateString: String
    
    private static let cache = NSCache<NSString, UIImage>()
    
    // MARK: Initialization
    
    public init(json: [String: Any]) throws {
        guard let height = json[JSONKeys.height] as? Int else {
            throw SerializationError.missing(JSONKeys.height)
        }
        
        guard let width = json[JSONKeys.width] as? Int else {
            throw SerializationError.missing(JSONKeys.width)
        }
        
        guard let urlTemplateString = json[JSONKeys.url] as? String else {
            throw SerializationError.missing(JSONKeys.url)
        }
        
        self.height = height
        self.width = width
        self.urlTemplateString = urlTemplateString
    }
    
    // MARK: Image URL Generation Method
    public func imageURL(size: CGSize) -> URL {
        
        /*
         There are three pieces of information needed to create the URL for the image we want for a given size.  This information is the width, height
         and image format.  We can use this information in addition to the `urlTemplateString` to create the URL for the image we wish to use.
         */
        
        // 1) Replace the "{w}" placeholder with the desired width as an integer value.
        var imageURLString = urlTemplateString.replacingOccurrences(of: "{w}", with: "\(Int(size.width))")
        
        // 2) Replace the "{h}" placeholder with the desired height as an integer value.
        imageURLString = imageURLString.replacingOccurrences(of: "{h}", with: "\(Int(size.width))")
        
        // 3) Replace the "{f}" placeholder with the desired image format.
        imageURLString = imageURLString.replacingOccurrences(of: "{f}", with: "png")
        
        print(imageURLString)
        print("\n\n\n\n\n\n\n\n\n\n\n\n")
        return URL(string: imageURLString)!
    }
    
    /// Loads the image with a given size.
    /// - Parameter size: The size to load the image at.
    /// - Parameter completion: A completion block, which will contain the image if loaded when called.
    public func load(withSize size: CGSize, andCompletion completion: @escaping (UIImage?)->Void) {
        let url = self.imageURL(size: size)
        
        if let image = MKMediaItemArtwork.cache.object(forKey: NSString(string: url.absoluteString)) {
            completion(image)
            return
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    completion(nil)
                    return
                }
                
                completion(image)
                MKMediaItemArtwork.cache.setObject(image, forKey: NSString(string: url.absoluteString))
            }
            catch {
                print(error)
                completion(nil)
            }
        }
    }
}


#endif
