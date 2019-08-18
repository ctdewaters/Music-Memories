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
        var bitmap = [UInt8](repeating: 0, count: 4)

        let context = CIContext(options: nil)
        let cgImg = context.createCGImage(CoreImage.CIImage(cgImage: self.cgImage!), from: CoreImage.CIImage(cgImage: self.cgImage!).extent)

        let inputImage = CIImage(cgImage: cgImg!)
        let extent = inputImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: inputExtent])!
        let outputImage = filter.outputImage!
        let outputExtent = outputImage.extent
        assert(outputExtent.size.width == 1 && outputExtent.size.height == 1)

        // Render to bitmap.
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: CIFormat.RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        // Compute result.
        let result = UIColor(red: CGFloat(bitmap[0]) / 255.0, green: CGFloat(bitmap[1]) / 255.0, blue: CGFloat(bitmap[2]) / 255.0, alpha: alpha)
        return result
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
