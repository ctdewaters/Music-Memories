//
//  CDHUDSuccessCheckmark.swift
//  Music Memories
//
//  Created by Collin DeWaters on 7/20/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class CDHUDSuccessCheckmark: CAShapeLayer {
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    //MARK: - Initialization
    init(withFrame frame: CGRect, andTintColor tintColor: UIColor = .success, andLineWidth lineWidth: CGFloat = 10.0, withOutlineCircle withCircle: Bool = false) {
        super.init()
        //Set the frame
        self.frame = frame
        
        //Make the path
        let path = UIBezierPath()
        path.move(to: CGPoint(x: frame.width / 8, y: frame.height / 3 * 1.5))
        path.addLine(to: CGPoint(x: 1.25 * frame.width / 3, y: frame.height * 0.85))
        path.addLine(to: CGPoint(x: frame.width, y: 0))
        
        //Create the circle path
        if withCircle {
            let circle = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), radius: 1.5 * frame.width / 2, startAngle: 7 * CGFloat.pi / 4, endAngle: (7 * CGFloat.pi / 4) + (2 * CGFloat.pi), clockwise: true)            
            path.append(circle)
        }
        
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
    func animate(withDuration duration: TimeInterval, backwards: Bool = false) {
        //Create the animation object.
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = backwards ? 1 : 0
        animation.toValue = backwards ? 0 : 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        //Remove prior animations.
        self.removeAllAnimations()
        
        //Add the animation
        self.add(animation, forKey: "drawCheckmark")
        
        self.strokeEnd = backwards ? 0 : 1
    }
}
