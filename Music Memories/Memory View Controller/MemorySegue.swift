//
//  MemorySegue.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/12/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

//MARK: - MemorySegue: the segue used to open and close a memory.
class MemorySegue: UIStoryboardSegue {
    
    ///Determines whether to run the segue as a forwards or backwards animation.
    var back = false
    
    ///The frame to animate the memory view controller from.
    var sourceFrame = CGRect.zero
    
    override func perform() {
        if back {
            //Closing memory.
            
            let source = self.source as! MemoryViewController
            let destination = homeVC
            
            source.view.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(source.view)
            
            
            //Transform and center animation.
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear, animations: {
                source.view.transform = CGAffineTransform(scaleX: self.sourceFrame.width / source.view.frame.width, y: self.sourceFrame.height / source.view.frame.height)
                source.view.center = UIApplication.shared.keyWindow?.center ?? .zero
            }, completion: nil)
            
            //Move to source cell animation.
            UIView.animate(withDuration: 0.25, delay: 0.15, options: .curveEaseIn, animations: {
                source.view.center = CGPoint(x: self.sourceFrame.midX, y: self.sourceFrame.midY)
            }, completion: { (complete) in
                if complete {
                    source.dismiss(animated: false) {
                        source.view.transform = .identity
                        source.view.alpha = 1
                    }
                }
            })
            
            //Alpha animation.
            UIView.animate(withDuration: 0.05, delay: 0.35, options: .curveLinear, animations: {
                destination?.selectedCell?.alpha = 1
            }, completion: nil)
            
            //Corner radius animation.
            source.view.addCornerRadiusAnimation(from: 0, to: 20, duration: 0.3)


            
            return
        }
        //Opening memory.
        
        let source = self.source as! HomeViewController
        let destination = self.destination as! MemoryViewController
        
        destination.view.frame = self.sourceFrame
        destination.view.clipsToBounds = true
        destination.view.layer.cornerRadius = 20
        destination.sourceFrame = self.sourceFrame
        
        UIApplication.shared.keyWindow?.addSubview(destination.view)
        
        destination.headerHeightConstraint.constant = 0
        destination.view.layoutIfNeeded()
        
        source.selectedCell?.alpha = 0
        
        //Move to center animation.
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            destination.headerHeightConstraint.constant = destination.maximumHeaderHeight
            destination.view.layoutIfNeeded()
            destination.view.center = UIApplication.shared.keyWindow?.center ?? .zero
        }, completion: nil)

        //Grow animation

        UIView.animate(withDuration: 0.75, delay: 0.14, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            destination.view.frame.size = UIApplication.shared.keyWindow?.bounds.size ?? .zero
            destination.view.center = UIApplication.shared.keyWindow?.center ?? .zero
        }, completion: { (complete) in
            if complete {
                source.present(destination, animated: false, completion: nil)
            }
        })

        //Corner radius animation
        destination.view.addCornerRadiusAnimation(from: 20, to: 0, duration: 0.32)
    }

}

extension UIView {
    //Animates the corner raidus of a view.
    func addCornerRadiusAnimation(from: CGFloat, to: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath:"cornerRadius")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        layer.add(animation, forKey: "cornerRadius")
        layer.cornerRadius = to
    }
}
