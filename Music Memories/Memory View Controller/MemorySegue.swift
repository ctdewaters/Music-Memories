//
//  MemorySegue.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/12/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

var memoryOpenBlurOverlay: UIVisualEffectView?

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
            let destination = homeVC!
            
            source.view.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(source.view)
            
            source.view.addCornerRadiusAnimation(from: 0, to: 40, duration: 0.05)
            
            //Prepare the cell overlay.
            let cellView: MemoryCellView = .fromNib()
            cellView.setup(withMemory: source.memory)
            cellView.alpha = 0
            cellView.backgroundColor = Settings.shared.darkMode ? .black : .white
            cellView.state = Settings.shared.darkMode ? .dark : .light
            
            //Add the cell overlay after a delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                UIApplication.shared.keyWindow?.addSubview(cellView)
                cellView.center = UIApplication.shared.keyWindow?.center ?? .zero
                cellView.frame.size = destination.isPortrait() ? CGSize(width: destination.view.frame.width / 2 - 20, height: destination.view.frame.width / 2 - 20) :
                    CGSize(width: destination.view.frame.width / 3 - 30, height: destination.view.frame.width / 3 - 30)
                source.view.alpha = 0
                
                //Cell view alpha animation.
                UIView.animate(withDuration: 0.1) {
                    cellView.alpha = 1
                }
                
                //Move to source cell animation.
                UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
                    cellView.center = CGPoint(x: self.sourceFrame.midX, y: self.sourceFrame.midY)
                }, completion: { (complete) in
                    if complete {
                        memoryOpenBlurOverlay?.removeFromSuperview()
                        cellView.removeFromSuperview()
                        source.view.removeFromSuperview()
                        source.view.transform = .identity
                        source.view.alpha = 1
                    }
                })

            }
            
            //Transform and center animation.
            UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: {
                source.view.transform = CGAffineTransform(scaleX: self.sourceFrame.width / source.view.frame.width, y: self.sourceFrame.height / source.view.frame.height)
                source.view.center = UIApplication.shared.keyWindow?.center ?? .zero
                
                memoryOpenBlurOverlay?.effect = nil
            }, completion: nil)
            
            //Alpha animation.
            UIView.animate(withDuration: 0.05, delay: 0.35, options: .curveLinear, animations: {
                destination.selectedCell?.alpha = 1
            }, completion: nil)
            
            return
        }
        //Opening memory.
        
        let source = self.source as! HomeViewController
        let destination = self.destination as! MemoryViewController
        
        destination.view.frame = self.sourceFrame
        destination.view.clipsToBounds = true
        destination.view.layer.cornerRadius = 20
        destination.sourceFrame = self.sourceFrame
        
        //Prepare the blur overlay.
        memoryOpenBlurOverlay = UIVisualEffectView(effect: nil)
        memoryOpenBlurOverlay?.frame = UIApplication.shared.keyWindow?.bounds ?? .zero
        memoryOpenBlurOverlay?.center = UIApplication.shared.keyWindow?.center ?? .zero
        
        UIApplication.shared.keyWindow?.addSubview(memoryOpenBlurOverlay!)
        
        UIApplication.shared.keyWindow?.addSubview(destination.view)
        
        destination.headerHeightConstraint.constant = 0
        destination.view.layoutIfNeeded()
        
        source.selectedCell?.alpha = 0
        
        //Move to center animation.
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            destination.headerHeightConstraint.constant = destination.maximumHeaderHeight
            destination.view.layoutIfNeeded()
            destination.view.center = UIApplication.shared.keyWindow?.center ?? .zero
            
            memoryOpenBlurOverlay?.effect = Settings.shared.blurEffect
        }, completion: nil)

        //Grow animation
        UIView.animate(withDuration: 0.75, delay: 0.14, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            destination.view.frame.size = UIApplication.shared.keyWindow?.bounds.size ?? .zero
            destination.view.center = UIApplication.shared.keyWindow?.center ?? .zero
        }, completion: { (complete) in
            if complete {
                UIApplication.shared.keyWindow?.bringSubview(toFront: source.view)
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
    
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
    }

}
