//
//  CDHUDLoadingIndicator.swift
//  Bartr
//
//  Created by Collin DeWaters on 8/8/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class CDHUDLoadingIndicatorGraphic: CAShapeLayer {

    //The animation layer.
    private var animationLayer: CAShapeLayer!
    
    //The length of the animation layer.
    let animationLayerLength: CGFloat = 0.05

    
    //MARK: - Initialization
    init(withFrame frame: CGRect, andTintColor tintColor: UIColor = .white, andLineWidth lineWidth: CGFloat = 10.0) {
        super.init()
        //Set the frame
        self.frame = frame
        
        //Make the path
        let path = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), radius: frame.width / 2, startAngle: 7 * CGFloat.pi / 4, endAngle: (7 * CGFloat.pi / 4) + (2 * CGFloat.pi), clockwise: true)
        
        //Set this layer's path
        self.path = path.cgPath
        
        //Set and add the animation layer
        self.animationLayer = CAShapeLayer()
        self.animationLayer.frame = self.frame
        self.animationLayer.path = path.cgPath
        self.addSublayer(self.animationLayer)
        
        //Set the colors
        self.strokeColor = tintColor.withAlphaComponent(0.25).cgColor
        self.animationLayer.strokeColor = tintColor.cgColor
        self.fillColor = nil
        self.animationLayer.fillColor = nil
        
        //Set the line types.
        self.lineWidth = lineWidth
        self.lineJoin = kCALineJoinRound
        self.lineCap = kCALineCapRound
        self.animationLayer.lineWidth = lineWidth
        self.animationLayer.lineJoin = kCALineJoinRound
        self.animationLayer.lineCap = kCALineCapRound
        
        self.animationLayer.strokeStart = 0
        self.animationLayer.strokeEnd = animationLayerLength
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Animation functions.
    func animate(withDuration duration: CFTimeInterval) {
        //Stroke start animation.
        let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
        strokeStartAnimation.fromValue = 0
        strokeStartAnimation.toValue = 1
        strokeStartAnimation.repeatCount = Float.infinity
        strokeStartAnimation.duration = duration

        //Stroke end animation.
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = self.animationLayerLength
        strokeEndAnimation.toValue = 1 + self.animationLayerLength
        strokeEndAnimation.repeatCount = Float.infinity
        strokeEndAnimation.duration = duration
        
        //Add the animations to the animation layer.
        self.animationLayer.add(strokeStartAnimation, forKey: "strokeStartAnimation")
        self.animationLayer.add(strokeEndAnimation, forKey: "strokeEndAnimation")
    }
    
    //Removes all animations.
    func removeAnimations() {
        self.animationLayer.removeAllAnimations()
    }

}
