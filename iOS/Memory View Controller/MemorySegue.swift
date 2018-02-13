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
            
            destination.selectedCell?.alpha = 0
            
            source.view.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(source.view)
            
            let slow: TimeInterval = 1

            source.view.addCornerRadiusAnimation(from: 0, to: 40, duration: 0.05 * slow)
            
            //Prepare the cell overlay.
            let cellView: MemoryCellView = .fromNib()
            cellView.setup(withMemory: source.memory)
            cellView.alpha = 0
            cellView.backgroundColor = Settings.shared.darkMode ? .black : .white
            cellView.state = Settings.shared.darkMode ? .dark : .light
            cellView.memoryImagesDisplayView = source.memoryImagesDisplayView
            
            //Add the cell view after a delay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14 * slow) {
                UIApplication.shared.keyWindow?.addSubview(cellView)
                cellView.center = UIApplication.shared.keyWindow?.center ?? .zero
                cellView.frame.size = destination.isPortrait() ? CGSize(width: destination.view.frame.width / 2 - 20, height: destination.view.frame.width / 2 - 20) :
                    CGSize(width: destination.view.frame.width / 3 - 30, height: destination.view.frame.width / 3 - 30)
                source.view.alpha = 0
                
                //Cell view alpha animation.
                UIView.animate(withDuration: 0.1 * slow) {
                    cellView.alpha = 1
                }
                
                //Move to source cell animation.
                UIView.animate(withDuration: 0.25 * slow, delay: 0, options: .curveEaseIn, animations: {
                    cellView.center = CGPoint(x: self.sourceFrame.midX, y: self.sourceFrame.midY)
                }, completion: { (complete) in
                    if complete {
                        memoryOpenBlurOverlay?.removeFromSuperview()
                        cellView.removeFromSuperview()
                        
                        //Add the memory images display view back to the selected cell's image view.
                        if let memoryImagesDisplayView = cellView.memoryImagesDisplayView {
                            destination.selectedCell?.image.addSubview(memoryImagesDisplayView)
                            memoryImagesDisplayView.bindFrameToSuperviewBounds()
                        }
                        
                        destination.selectedCell?.alpha = 1
                        
                        source.view.removeFromSuperview()
                        source.view.transform = .identity
                        source.view.alpha = 1
                    }
                })

            }
            
            //Transform and center animation.
            UIView.animate(withDuration: 0.15 * slow, delay: 0 * slow, options: .curveLinear, animations: {
                source.view.transform = CGAffineTransform(scaleX: (self.sourceFrame.width / source.view.frame.width) * 0.8, y: (self.sourceFrame.height / source.view.frame.height) * 0.8)
                source.view.center = UIApplication.shared.keyWindow?.center ?? .zero
                
                memoryOpenBlurOverlay?.effect = nil
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
        
        print("DESINATION MEMORY FROM SEGUE: ")
        print(destination.memory)
        
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
                
                //Update the status bar color (light content to accommodate images in destination view controller).
                UIApplication.shared.statusBarStyle = .lightContent
                
            }
        })

        //Corner radius animation
        destination.view.addCornerRadiusAnimation(from: 40, to: 0, duration: 0.75)
    }

}
