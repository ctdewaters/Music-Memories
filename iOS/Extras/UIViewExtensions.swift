//
//  UIViewExtension.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/7/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

//Extension for retrieving a UIView from a .xib file.
extension UIView {
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    
    /* The color of the shadow. Defaults to opaque black. Colors created
     * from patterns are currently NOT supported. Animatable. */
    var shadowColor: UIColor? {
        set {
            layer.shadowColor = newValue!.cgColor
        }
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            else {
                return nil
            }
        }
    }
    
    /* The opacity of the shadow. Defaults to 0. Specifying a value outside the
     * [0,1] range will give undefined results. Animatable. */
    var shadowOpacity: Float {
        set {
            layer.shadowOpacity = newValue
        }
        get {
            return layer.shadowOpacity
        }
    }
    
    /* The shadow offset. Defaults to (0, -3). Animatable. */
    var shadowOffset: CGPoint {
        set {
            layer.shadowOffset = CGSize(width: newValue.x, height: newValue.y)
        }
        get {
            return CGPoint(x: layer.shadowOffset.width, y:layer.shadowOffset.height)
        }
    }
    
    /* The blur radius used to create the shadow. Defaults to 3. Animatable. */
    var shadowRadius: CGFloat {
        set {
            layer.shadowRadius = newValue
        }
        get {
            return layer.shadowRadius
        }
    }
    
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
    
    //Constraint functions.
    
    ///Binds this view to its superview.
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
        superview.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subview]-0-|", options: .directionLeadingToTrailing, metrics: nil, views: ["subview": self]))
    }
    
    ///Clears all constraints associated with this view.
    func clearConstraints() {
        self.removeConstraints(self.constraints)
    }
    
    func setHeightConstraint(toValue value: CGFloat) {
        self.heightAnchor.constraint(equalToConstant: value).isActive = true
        self.layoutIfNeeded()
    }
    
    func setWidthConstraint(toValue value: CGFloat) {
        self.widthAnchor.constraint(equalToConstant: value).isActive = true
        self.layoutIfNeeded()
    }
    
    func setTopConstraint(withConstant constant: CGFloat, withReferenceAnchor anchor: NSLayoutAnchor<NSLayoutYAxisAnchor>) {
        self.topAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        self.layoutIfNeeded()
    }
    
    func setLeadingConstraint(withConstant constant: CGFloat, withReferenceAnchor anchor: NSLayoutAnchor<NSLayoutXAxisAnchor>) {
        self.leadingAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        self.layoutIfNeeded()
    }
    
    func setTrailingConstraint(withConstant constant: CGFloat, withReferenceAnchor anchor: NSLayoutAnchor<NSLayoutXAxisAnchor>) {
        self.trailingAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        self.layoutIfNeeded()
    }
    
    //MARK: - Parallax
    func addParallaxEffect(withMovementConstant constant: CGFloat) {
        let min = -constant
        let max = constant
        
        let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x", type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = min
        xMotion.maximumRelativeValue = max
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y", type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = min
        yMotion.maximumRelativeValue = max
        
        let motionEffectGroup = UIMotionEffectGroup()
        motionEffectGroup.motionEffects = [xMotion,yMotion]
        
        self.addMotionEffect(motionEffectGroup)
    }
    
    func removeParallax() {
        for motionEffect in self.motionEffects {
            print("REMOVING MOTION EFFECT \(motionEffect)")
            self.removeMotionEffect(motionEffect)
        }
    }
    
}

extension UILabel {
    ///Animates the label to a new font.
    func animateToFont(_ font: UIFont, withDuration duration: TimeInterval) {
        let oldFont = self.font
        self.font = font
        // let oldOrigin = frame.origin
        let labelScale = oldFont!.pointSize / font.pointSize
        let oldTransform = transform
        transform = transform.scaledBy(x: labelScale, y: labelScale)
        // let newOrigin = frame.origin
        // frame.origin = oldOrigin
        setNeedsUpdateConstraints()
        UIView.animate(withDuration: duration) {
            //    self.frame.origin = newOrigin
            self.transform = oldTransform
            self.layoutIfNeeded()
        }
    }
}

///MARK: - UIColor extension
extension UIColor {
    static let themeColor = #colorLiteral(red: 0.93728894, green: 0.2049360275, blue: 0.3079802692, alpha: 1)
    static let error = #colorLiteral(red: 1, green: 0.1346225441, blue: 0.005045979749, alpha: 1)
    static let success = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    
}



//MARK: - String extension.
extension String {
    ///Returns the height of a String with a constrainted width and font.
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.height)
    }
    
    ///Returns the width of a String with a constrainted height and font.
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        
        return ceil(boundingBox.width)
    }
}


//MARK: - Date Extension.
extension Date {
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return tomorrow.month != month
    }
    
    func add(days: Int = 0, months: Int = 0, years: Int = 0) -> Date? {
        var dateComponent = DateComponents()
        
        dateComponent.month = months
        dateComponent.day = days
        dateComponent.year = years
        
        return Calendar.current.date(byAdding: dateComponent, to: self)
    }
}


