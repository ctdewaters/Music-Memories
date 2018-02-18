//
//  MemoryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MarqueeLabel
import WatchConnectivity
import MediaPlayer
import DeviceKit

class MemoryViewController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var memory: MKMemory!
    
    //MARK: - IBOutlets
    @IBOutlet weak var memoryCollectionView: MemoryCollectionView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var imagesHoldingView: UIView!
    @IBOutlet weak var headerGradient: UIImageView!
    @IBOutlet weak var headerBlur: UIVisualEffectView!
    
    //MARK - Constraint outlets
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButtonTopConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    ///The minimum height of the header.
    var minimumHeaderHeight: CGFloat!
    
    ///The maximum height of the header.
    var maximumHeaderHeight: CGFloat!
    
   //The source frame, from which this view was presented.
    var sourceFrame = CGRect.zero
    
    ///The content inset of the collection view.
    var contentInset: CGFloat!
    
    ///The pan gesture recognizer, responsible for the slide right to close feature.
    var panGesture: UIPanGestureRecognizer?
    
    ///The memory images display view, which will display (and animate, if more than four) the images of the associated memory.
    weak var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The blur animation property animator.
    var headerBlurPropertyAnimator: UIViewPropertyAnimator!
        
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the max and min header height values.
        self.minimumHeaderHeight = self.view.safeAreaInsets.top + 140
        self.maximumHeaderHeight = self.view.safeAreaInsets.top + self.view.frame.width

        // Do any additional setup after loading the view.
        self.memoryCollectionView.set(withMemory: self.memory)
        self.memoryCollectionView.scrollCallback = { offset in
            self.collectionViewDidScroll(withOffset: offset)
        }
        
        self.headerBlur.effect = nil
        self.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            self.headerBlur.effect = Settings.shared.blurEffect
        }
                
        //Set title.
        self.titleTextView.text = self.memory.title ?? ""
        
        //Set close button.
        self.closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        self.closeButton.layer.cornerRadius = 30 / 2
        
        //Setup pan gesture recognizer.
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.pan))
        self.panGesture?.delegate = self
        self.view.addGestureRecognizer(self.panGesture!)
        
        self.view.clipsToBounds = true
        
        NotificationCenter.default.addObserver(forName: AppDelegate.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { (notification) in
            //self.memoryCollectionView.reload()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        //Determine the background color of the memory collection view.
        self.memoryCollectionView.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Set the content inset of the collection view.
        self.contentInset = self.maximumHeaderHeight - (Device() == .iPhoneX ? 35 : 20)
        self.memoryCollectionView.contentInset.top = contentInset
        
        //Pull the memory images display view from the selected cell.
        self.memoryImagesDisplayView = homeVC?.selectedCell?.memoryImagesDisplayView
        self.memoryImagesDisplayView?.removeFromSuperview()
        
        self.view.layer.cornerRadius = 35
        
        //Add observer for MPMediaItemDidChange.
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemDidChange), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemStateDidChange), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Add the images display view to the images holding view.
        if let memoryImagesDisplayView = self.memoryImagesDisplayView {
            self.imagesHoldingView.addSubview(memoryImagesDisplayView)
            memoryImagesDisplayView.setHeightConstraint(toValue: self.maximumHeaderHeight + 15)
            memoryImagesDisplayView.setTopConstraint(withConstant: -15, withReferenceAnchor: self.imagesHoldingView.topAnchor)
            memoryImagesDisplayView.setLeadingConstraint(withConstant: -15, withReferenceAnchor: self.imagesHoldingView.leadingAnchor)
            memoryImagesDisplayView.setTrailingConstraint(withConstant: 15, withReferenceAnchor: self.imagesHoldingView.trailingAnchor)
            memoryImagesDisplayView.addParallaxEffect(withMovementConstant: 30)
            
            if memoryImagesDisplayView.memory?.images?.count ?? 0 > 3 {
                //Shift right and down by half the max header height.
                memoryImagesDisplayView.center.x += self.maximumHeaderHeight / 2
                memoryImagesDisplayView.center.y += self.maximumHeaderHeight / 2
            }
            
            self.imagesHoldingView.layoutIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.memoryImagesDisplayView?.removeParallax()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: AppDelegate.didBecomeActiveNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        //Remove notification center observers.
    }
    
    
    //MARK: - Collection view scrolling.
    func collectionViewDidScroll(withOffset offset: CGFloat) {
        //Normalize the offset (to account for the content inset supplied in view will appear).
        let normalizedOffset = offset + contentInset + self.view.safeAreaInsets.top
        self.headerHeightConstraint.constant = self.newHeaderHeight(withOffset: normalizedOffset)
        self.view.layoutIfNeeded()
        
        //The new ratio to apply to the title label font
        let newTitleRatio = self.titleTransform(withOffset: normalizedOffset).isNaN ? 1 : self.titleTransform(withOffset: normalizedOffset)
        
        //Blur and gradient alpha animation.
        let minRatio = 0.483870967741935
        let maxRatio = 1.0
        let range = maxRatio - minRatio
        let adjustedRatio = (newTitleRatio - CGFloat(minRatio)) / CGFloat(range)
        
        self.headerGradient.alpha = adjustedRatio + 0.5
        self.headerBlurPropertyAnimator.fractionComplete = 1 - adjustedRatio
        
        //Calculate the new font size
        let newFontSize: CGFloat = !newTitleRatio.isNaN ? 18 + (12 * newTitleRatio) : 30
        
        //Set the new values.
        self.titleTextView.animateToFont(UIFont.systemFont(ofSize:  newFontSize, weight: .bold), withDuration: 0.01)
    }
    
    //Calculating new header height.
    func newHeaderHeight(withOffset offset: CGFloat) -> CGFloat {
        var newHeight = self.maximumHeaderHeight - offset
        newHeight = newHeight > maximumHeaderHeight ? maximumHeaderHeight : newHeight < minimumHeaderHeight ? minimumHeaderHeight : newHeight
        return newHeight
    }
    
    //Calculating new title transform.
    func titleTransform(withOffset offset: CGFloat) -> CGFloat  {
        //Min and max ratio values.
        let max: CGFloat = 1
        let min: CGFloat = 0
        
        let heightDifference = (self.maximumHeaderHeight - self.minimumHeaderHeight) + 85
        
        var ratio = self.headerHeightConstraint.constant / heightDifference
        
        if ratio > max {
            //Determine rubber banding value.
            let invertedOffset = -offset
            let invertedRatio = invertedOffset / self.maximumHeaderHeight
            
            let rubberBandingRatio = sqrt(invertedRatio) / 2
            
            return max + rubberBandingRatio
        }
        
        //Normalize the ratio.
        ratio = ratio < min ? min : ratio
        
        return ratio
    }
    
    //MARK: - Pan Gesture
    ///The initial touch point of the pan gesture.
    var panInitialPoint: CGPoint?
    
    ///The pan function.
    @objc private func pan() {
        guard let panGesture = self.panGesture else {
            return
        }
        
        if panGesture.state == .began {
            self.panInitialPoint = panGesture.location(in: self.view)
            
            self.view.addCornerRadiusAnimation(from: 0, to: 40, duration: 0.1)
        }
        else if panGesture.state == .ended {
            self.memoryImagesDisplayView?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.panInitialPoint = nil
            //Return to original state.
            UIView.animate(withDuration: 0.75, delay: 0.14, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.view.transform = .identity
                self.view.addCornerRadiusAnimation(from: 40, to: 0, duration: 0.1)
            }, completion: nil)
            self.memoryCollectionView.isScrollEnabled = true
        }
        
        guard let initialPoint = self.panInitialPoint else {
            return
        }
        
        //Only run the scaling animation if the initial point's x value is less than 70.
        if initialPoint.x < 70 {
            self.view.layer.masksToBounds = true
            
            let xTranslation = panGesture.translation(in: self.view).x
                        
            self.memoryCollectionView.isScrollEnabled = xTranslation > 40 ? false : true
            
            self.animateToNewSize(withXTranslation: xTranslation)
        }
    }
    
    ///Animates the view to a new size based on the x translation of the pan gesture.
    private func animateToNewSize(withXTranslation xTranslation: CGFloat) {
        //The x translation to run the exit segue when reached.
        let destinationXTranslation: CGFloat = UIScreen.main.bounds.width * 0.3
        
        //The max scale factor for decreasing the size of the view.
        let maxScaleFactor: CGFloat = 0.2
        
        //Calculating the ratio to change the size of the view.
        let ratio = (xTranslation / destinationXTranslation) < 0 ? 0 : (xTranslation / destinationXTranslation) > 1 ? 1 : (xTranslation / destinationXTranslation)
        
        if ratio == 1 {
            //Close the memory.
            self.view.transform = .identity
            self.close(self)
            return
        }
        else if ratio == 0 {
            self.view.transform = .identity
            return
        }
        
        //Change the transform of the view.
        self.view.transform = CGAffineTransform(scaleX: (1 - (maxScaleFactor * ratio)), y: (1 - (maxScaleFactor * ratio)))
    }
    
    //MARK: - UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGesture {
            return false
        }
        return true
    }
    
    //MARK: - Now Playing Notifications
    @objc func nowPlayingItemDidChange() {
        //Update the now playing UI in the collection view.
        self.memoryCollectionView.updateNowPlayingUI()
    }
    
    @objc func nowPlayingItemStateDidChange() {
        self.memoryCollectionView.updateNowPlayingUIState()
    }
    
    //MARK: - Close button
    ///Determines if we should delete the memory after the animation.
    var deleteOnClose = false

    ///Signals for the close segue.
    @IBAction func close(_ sender: Any) {
        self.deleteOnClose = sender is MemoryCollectionView
        self.memoryCollectionView.setNowPlayingToIdle()
        self.performSegue(withIdentifier: "closeMemory", sender: self)
    }
    
    ///Plays the memory.
    @IBAction func play(_ sender: Any) {
        MKMusicPlaybackHandler.play(memory: self.memory)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "closeMemory" {
            let segue = segue as! MemorySegue
            segue.back = true
            segue.delete = self.deleteOnClose
            segue.sourceFrame = self.sourceFrame
        }
    }
}

