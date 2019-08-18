//
//  Extensions.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/25/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import LibraryKit

//MARK: - UIViewController extension.
public extension UIViewController {
    public func hideHairline() {
        self.findNavigationBarHairline()?.isHidden = true
        self.findTabBarHairline()?.isHidden = true
    }
    
    public func showHairline() {
        self.findNavigationBarHairline()?.isHidden = false
        self.findTabBarHairline()?.isHidden = false
    }
    
    private func findNavigationBarHairline() -> UIImageView? {
        let flatMap = navigationController?.navigationBar.subviews.flatMap { $0.subviews }
        let compactMap = flatMap?.compactMap { $0 as? UIImageView }
        let f1 = compactMap?.filter { $0.bounds.size.width == self.navigationController?.navigationBar.bounds.size.width }
        let f2 = f1?.filter { $0.bounds.size.height <= 2 }
        return f2?.first
    }
    
    private func findTabBarHairline() -> UIImageView? {
        let flatMap = tabBarController?.tabBar.subviews.flatMap { $0.subviews }
        let compactMap = flatMap?.compactMap { $0 as? UIImageView }
        let f1 = compactMap?.filter { $0.bounds.size.width == self.navigationController?.navigationBar.bounds.size.width }
        let f2 = f1?.filter { $0.bounds.size.height <= 2 }
        return f2?.first
    }
    
    ///Sets up the navigation bar to match the overall design.
    @objc func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        self.tabBarController?.tabBar.setValue(true, forKey: "hidesShadow")
        self.edgesForExtendedLayout = .all
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    ///If true, the device is displaying as an iPad.
    var isPad: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad && self.view.frame.width >= 678.0 {
            return true
        }
        return false
    }
}

extension UIImage {
    
    func averageColor(alpha : CGFloat) -> UIColor {
        
        let rawImageRef : CGImage = self.cgImage!
        let  data : CFData = rawImageRef.dataProvider!.data!
        let rawPixelData  =  CFDataGetBytePtr(data);
        
        let imageHeight = rawImageRef.height
        let imageWidth  = rawImageRef.width
        let bytesPerRow = rawImageRef.bytesPerRow
        let stride = rawImageRef.bitsPerPixel / 6
        
        var red = 0
        var green = 0
        var blue  = 0
        
        
        
        
        for row in 0...imageHeight {
            var rowPtr = rawPixelData! + bytesPerRow * row
            for _ in 0...imageWidth {
                red    += Int(rowPtr[0])
                green  += Int(rowPtr[1])
                blue   += Int(rowPtr[2])
                rowPtr += Int(stride)
            }
        }
        
        let  f : CGFloat = 1.0 / (255.0 * CGFloat(imageWidth) * CGFloat(imageHeight))
        return UIColor(red: f * CGFloat(red), green: f * CGFloat(green), blue: f * CGFloat(blue) , alpha: alpha)
    }
}

extension Array {
    var copy: Array {
        var copiedArray = Array()
        for item in self {
            copiedArray.append(item)
        }
        return copiedArray
    }
    
    func subarray(startingAtIndex index: Int) -> Array {
        var copiedArray = Array()
        for i in 0..<count {
            if i >= index {
                copiedArray.append(self[i])
            }
        }
        return copiedArray
    }
}
