//
//  CDHUD.swift
//  Music Memories
//
//  Created by Collin DeWaters on 7/19/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

///Custom HUD class to show app events like successes, errors, and processing.
class CDHUD: UIVisualEffectView {
    
    struct Style {
        static let light = UIBlurEffect(style: .light)
        static let dark = UIBlurEffect(style: .dark)
    }

    //Defines the type of content shown to the user.
    enum ContentType {
        case error(title: String?)
        case success(title: String?)
        case processing(title: String?)
        
        var description: String? {
            switch self {
            case let .error(title) :
                return title
            case let .success(title) :
                return title
            case let .processing(title) :
                return title
            }
        }
    }
    
    //MARK: - Convenience variables
    //The background effect of the view
    var style: UIVisualEffect? {
        set {
            self.effect = newValue
        }
        get {
            return self.effect
        }
    }
    
    ///The color of the content subviews
    var contentTintColor: UIColor? {
        set {
            self.titleLabel?.textColor = newValue
            self.imageView?.tintColor = newValue
        }
        get {
            return self.titleLabel?.textColor
        }
    }
    
    //MARK: - Content subview properties.
    //The title label, if a title was passed with the content type.
    var titleLabel: UILabel?
    //The image view (shows X or checkmark for .error or .success respectively).
    var imageView: UIImageView?
    
    //Success and error graphics.
    var successCheckmark: CDHUDSuccessCheckmark?
    var errorGraphic: CDHUDErrorGraphic?
    var loadingGraphic: CDHUDLoadingIndicatorGraphic?
    
    //The current content type.
    var contentType: CDHUD.ContentType!
    
    //Singleton instance
    static let shared: CDHUD = CDHUD()
    
    //Superview cover.
    var superviewCover: UIView?
    
    //MARK: - Initialization
    init() {
        super.init(effect: nil)
        
        self.frame = CGRect(x: 0, y: 0, width: 150.0, height: 150.0)
        
        //Add the content views.
        self.sizeAndPositionContentViews()
    }
    
    //MARK: - Presentation functions
    func present(animated: Bool, withContentType contentType: CDHUD.ContentType, toView view: UIView, removeAfterDelay delay: TimeInterval? = nil, coverSuperview: Bool = true) {
        
        self.contentType = contentType
        
        self.style = Settings.shared.blurEffect
        
        //Check if the HUD is already added to the passed UIView.
        if self.superview == view {
            //Transition content views to satisfy the new content type.
            self.setContentViews(withContentType: contentType)
            //Set the image view.
            //self.setImageView(withContentType: contentType)
            
            //If delay passed, dismiss after the delay.
            if let delay = delay {
                self.dismiss(animated: animated, afterDelay: delay)
            }
            
            return
        }
        
        //Restore.
        self.restore()
        
        //Set frame and position.
        self.frame = CGRect(x: 0, y: 0, width: 150.0, height: 150.0)
        self.center = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        
        //Setup
        //Corner radius
        self.setCornerRadius()
        //Content views
        self.setContentViews(withContentType: contentType)
        //Set the image view.
        self.setImageView(withContentType: contentType)
        
        if coverSuperview {
            //Setup the cover view.
            self.setCoverView(toView: view)
        }
        
        //Add to the passed view.
        view.addSubview(self)
        if animated {
            self.animate(entry: true, withExitDelay: delay)
            return
        }
        
        //If delay passed, dismiss after the delay.
        if let delay = delay {
            self.dismiss(animated: animated, afterDelay: delay)
        }
    }
    
    func setCoverView(toView view: UIView) {
        if superviewCover == nil {
            self.superviewCover = UIView(frame: view.frame)
            self.superviewCover?.backgroundColor = Settings.shared.darkMode ? UIColor.black.withAlphaComponent(0.55) : UIColor.white.withAlphaComponent(0.55)
            view.addSubview(self.superviewCover!)
        }
    }
    
    //MARK: - Animation functions
    func animate(entry: Bool, withExitDelay delay: TimeInterval? = nil) {
        if entry {
            //Entry animation
            //Set the transform in preparation of animation.
            self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.superviewCover?.alpha = 0
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                //Overshoot identity transform for "pop" effect.
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.superviewCover?.alpha = 1
            }, completion: { (completed) in
                if completed {
                    //Return to the identity transform.
                    UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
                        self.transform = CGAffineTransform.identity
                    }, completion: { (completed) in
                        if completed {
                            //Set the image view and animate.
                            DispatchQueue.main.async {
                                //If delay passed, dismiss after the delay.
                                if let delay = delay {
                                    self.dismiss(animated: true, afterDelay: delay)
                                }
                            }
                        }
                    })
                }
            })
            return
        }
        //Exit animation
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            self.superviewCover?.alpha = 0
        }, completion: { (completed) in
            if completed {
                self.restore()
            }
        })
    }
    
    //MARK: - Setup functions.
    //Corner radius
    private func setCornerRadius() {
        //Corner radius
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.width / 5
    }
    
    //Content views
    private func setContentViews(withContentType contentType: CDHUD.ContentType) {
        //Make sure title label isn't hidden.
        self.titleLabel?.isHidden = false
        
        switch contentType {
        case let .error(title), let .success(title), let .processing(title) :
            //Error or success content type passed.
            self.imageView?.isHidden = false
            //Set the title label.
            self.setTitleLabel(withTitle: title)
        }
    }
    
    //Sizing and positioning content views
    private func sizeAndPositionContentViews() {
        //Image view
        self.imageView = UIImageView(frame: CGRect(x: 0, y: 20, width: 60, height: 60))
        self.imageView?.center.x = self.frame.width / 2
        self.imageView?.contentMode = .scaleAspectFit
        self.contentView.addSubview(self.imageView!)
        
        //Title label
        self.titleLabel = UILabel(frame: CGRect(x: 0, y: self.frame.height - 55, width: self.frame.width - 15, height: 25))
        self.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.numberOfLines = 2
        self.contentView.addSubview(self.titleLabel!)
    }

    //Title label
    private func setTitleLabel(withTitle title: String?) {
        guard let title = title else {
            //Hide the title label.
            self.titleLabel?.isHidden = true
            //Move image view to center
            self.imageView?.center = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
            return
        }
        self.titleLabel?.text = title
        self.titleLabel?.sizeToFit()
        self.titleLabel?.center.x = self.frame.width / 2
        self.titleLabel?.textColor = Settings.shared.textColor
        
        //Check if label is one or two lines.
        if self.titleLabel!.frame.height <= 18.0 {
            //One line.
            self.titleLabel?.frame.origin.y = self.frame.height - 30
            self.imageView?.frame.origin.y = 35
        }
    }
    
    //Image view
    private func setImageView(withContentType contentType: CDHUD.ContentType) {
        //Remove all sublayers from the image view's layer.
        
        if let sublayers = self.imageView?.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
        }
    
        switch contentType {
        case .error(_) :
            //Set up the error graphic.
            self.errorGraphic = CDHUDErrorGraphic(withFrame: (self.imageView?.bounds)!)
            self.imageView?.layer.addSublayer(self.errorGraphic!)
            self.titleLabel?.textColor = .error
            break
        case .success(_) :
            //Set up the success graphic.
            self.successCheckmark = CDHUDSuccessCheckmark(withFrame: (self.imageView?.bounds)!)
            self.imageView?.layer.addSublayer(self.successCheckmark!)
            self.titleLabel?.textColor = .success
            
        case .processing(_) :
            self.loadingGraphic = CDHUDLoadingIndicatorGraphic(withFrame: CGRect(x: 0, y: 0, width: 35, height: 35), andTintColor: .themeColor, andLineWidth: 5)
            self.loadingGraphic?.position = CGPoint(x: (self.imageView?.frame.width)! / 2, y: (self.imageView?.frame.height)! / 2)
            self.imageView?.layer.addSublayer(self.loadingGraphic!)
            self.titleLabel?.textColor = .white
        }
        
        self.errorGraphic?.animate(withDuration: 0.5)
        self.successCheckmark?.animate(withDuration: 0.5)
        self.loadingGraphic?.animate(withDuration: 0.5)
    }
    
    //MARK: - Dismiss function
    func dismiss(animated: Bool, afterDelay delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if animated {
                //Animated
                self.animate(entry: false)
                
                return
            }
            //Not animated
            self.restore()
        }
    }
    
    //MARK: - Restore function
    //Restores the HUD to its original state.
    func restore() {
        //Remove from super view
        self.removeFromSuperview()
        
        //Return transform to identity
        self.transform = CGAffineTransform.identity
        
        //Remove subviews
        for view in self.contentView.subviews {
            view.removeFromSuperview()
        }
        
        //Set all subviews to nil
        self.titleLabel = nil
        self.imageView = nil
        self.loadingGraphic = nil
        self.successCheckmark = nil
        self.errorGraphic = nil
        self.superviewCover?.removeFromSuperview()
        self.superviewCover = nil
        
        //Add the subviews back again.
        self.sizeAndPositionContentViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
