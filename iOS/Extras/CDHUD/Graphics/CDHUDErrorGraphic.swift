//
//  CDHUDErrorGraphic.swift
//  Bartr
//
//  Created by Collin DeWaters on 7/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class CDHUDErrorGraphic: CAShapeLayer {
    
    //MARK: - Initialization
    init(withFrame frame: CGRect, andTintColor tintColor: UIColor = .error, andLineWidth lineWidth: CGFloat = 10.0) {
        super.init()
        //Set the frame
        self.frame = frame
        
        //Make the path
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: frame.width, y: frame.height))
        path.move(to: CGPoint(x: frame.width, y: 0))
        path.addLine(to: CGPoint(x: 0, y: frame.height))
        
        //Set this layer's path
        self.path = path.cgPath
        
        //Set the colors
        self.strokeColor = tintColor.cgColor
        self.fillColor = nil
        
        //Set the line types.
        self.lineWidth = lineWidth
        self.lineJoin = kCALineJoinRound
        self.lineCap = kCALineCapRound
        
        //Set the stroke end to zero in preparation for the drawing animation.
        self.strokeEnd = 0
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Animations
    func animate(withDuration duration: TimeInterval) {
        //Create the animation object.
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        //Remove prior animations.
        self.removeAllAnimations()
        
        //Add the animation
        self.add(animation, forKey: "drawCheckmark")
        
        self.strokeEnd = 1
        
    }
}

