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

///`MemoryViewController`: visually displays the contents and settings of a `MKMemory`.
class MemoryViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var memoryCollectionView: MemoryCollectionView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var imagesHoldingView: UIView!
    @IBOutlet weak var headerGradient: UIImageView!
    @IBOutlet weak var headerBlur: UIVisualEffectView!
    
    //MARK - Constraint outlets
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    ///The memory to display.
    weak var memory: MKMemory!

    ///The minimum height of the header.
    var minimumHeaderHeight: CGFloat!
    
    ///The maximum height of the header.
    var maximumHeaderHeight: CGFloat!
    
   //The source frame, from which this view was presented.
    var sourceFrame = CGRect.zero
    
    ///The content inset of the collection view.
    var contentInset: CGFloat!
    
    ///The memory images display view, which will display (and animate, if more than four) the images of the associated memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The blur animation property animator.
    var headerBlurPropertyAnimator: UIViewPropertyAnimator?
    
    ///If true, this view controller is being previewed.
    var isPreviewing = false
    
    ///The shared instance.
    public static var shared = mainStoryboard.instantiateViewController(withIdentifier: "memoryVC") as? MemoryViewController
    
    //MARK: - Resetting.
    public class func reset() {
        MemoryViewController.shared = nil
        MemoryViewController.shared = mainStoryboard.instantiateViewController(withIdentifier: "memoryVC") as? MemoryViewController
    }
        
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the max and min header height values.
        self.minimumHeaderHeight = (Device() == .iPhoneX ? 35 : 20) + 120
        self.maximumHeaderHeight = (Device() == .iPhoneX ? 35 : 20) + self.view.frame.width

        // Do any additional setup after loading the view.
        self.memoryCollectionView.set(withMemory: self.memory)
        self.memoryCollectionView.scrollCallback = { offset in
            self.collectionViewDidScroll(withOffset: offset)
        }
        
        //Header blur property animator.
        if self.headerBlurPropertyAnimator == nil && !self.isPreviewing {
            self.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.headerBlur.effect = Settings.shared.blurEffect
            }
        }
        self.headerBlur.effect = nil
        
        //Set title.
        self.titleTextView.text = self.memory.title ?? ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ///Clear nav bar.
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
                
        //Determine the background color of the memory collection view.
        self.memoryCollectionView.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Set the content inset of the collection view.
        self.contentInset = self.maximumHeaderHeight - (Device() == .iPhoneX ? 35 : 20) - 100
        self.memoryCollectionView.contentInset.top = contentInset
        
        //Setup memory images display view.
        self.setupMemoryImagesDisplayView()
        
        //Header blur property animator.
        if self.headerBlurPropertyAnimator == nil && !self.isPreviewing {
            self.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.headerBlur.effect = Settings.shared.blurEffect
            }
            self.headerBlur.effect = nil
        }
        
        //Add observer for MPMediaItemDidChange.
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemDidChange), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemStateDidChange), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        
        self.memoryCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: false)
                        
        //Light status bar style.
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        //Translucent nav bar.
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        
        //Return status bar style to the current setting.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Remove notification center observers.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: AppDelegate.didBecomeActiveNotification, object: nil)
        
        //Remove the memory images display view.
        self.memoryImagesDisplayView?.removeFromSuperview()
        self.memoryImagesDisplayView = nil
        
        //Remove the header blur property animator.
        self.headerBlurPropertyAnimator?.startAnimation()
        self.headerBlurPropertyAnimator?.stopAnimation(false)
        self.headerBlurPropertyAnimator?.finishAnimation(at: .current)
        self.headerBlurPropertyAnimator = nil

        if !self.isPreviewing && !self.memoryCollectionView.isEditing {
            //Reset the memory collection view.
            self.memoryCollectionView.memory = nil
            self.memoryCollectionView.itemsArray = nil
            self.memoryCollectionView.scrollCallback = nil
            
            //Set the memory to nil.
            self.memory = nil
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Preview action items.
    override var previewActionItems: [UIPreviewActionItem] {
        let delete = UIPreviewAction(title: "Delete", style: .destructive) { (action, viewController) in
            //Send delete message to user's Watch.
            self.memory.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .delete)
            
            //Delete the memory.
            self.deleteMemoryAndClose()
            
            //Reload the home view controller.
            homeVC?.reload()
            
            viewController.dismiss(animated: true, completion: nil)
        }
        
        return [delete]
    }
    
    //MARK: - Memory Images Display View setup.
    ///Sets up the memory images display view.
    private func setupMemoryImagesDisplayView() {
        if self.memoryImagesDisplayView == nil {
            //Add the images display view to the images holding view.
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: CGRect(x: 0, y: 0, width: self.maximumHeaderHeight + 45, height: self.maximumHeaderHeight + 45))
            self.imagesHoldingView.addSubview(self.memoryImagesDisplayView!)
            self.imagesHoldingView.backgroundColor = .lightGray
            
            //Center it, and add parallax.
            self.memoryImagesDisplayView?.center = CGPoint(x: self.imagesHoldingView.bounds.width / 2, y: (self.imagesHoldingView.bounds.height / 2) + 45)
            self.memoryImagesDisplayView?.addParallaxEffect(withMovementConstant: 30)
            
            //Set it up with the currently displayed memory.
            self.memoryImagesDisplayView?.set(withMemory: memory)
        }
    }
    
    //MARK: - Collection view scrolling.
    func collectionViewDidScroll(withOffset offset: CGFloat) {
        //Normalize the offset (to account for the content inset supplied in view will appear).
        let normalizedOffset = offset + self.contentInset + 140
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
        self.headerBlurPropertyAnimator?.fractionComplete = 1 - adjustedRatio
        
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
        
        let heightDifference = (self.maximumHeaderHeight - self.minimumHeaderHeight) + 65
        
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
        
    //MARK: - Now Playing Notifications
    @objc func nowPlayingItemDidChange() {
        //Update the now playing UI in the collection view.
        self.memoryCollectionView.updateNowPlayingUI()
    }
    
    @objc func nowPlayingItemStateDidChange() {
        self.memoryCollectionView.updateNowPlayingUIState()
    }
    
    //MARK: - Memory Deletion
    ///Signals for memory to be deleted, and pops this view controller.
    func deleteMemoryAndClose() {
        self.memoryCollectionView.setNowPlayingToIdle()
        //Cancel the memory reminder notification, if it was scheduled.
        AppDelegate.cancel(notificationRequestWithIdentifier: self.memory.storageID)
        //Delete the memory.
        self.memory.delete()
        //Pop this view controller.
        self.navigationController?.popViewController(animated: true)
    }
    
    ///Plays the memory.
    @IBAction func play(_ sender: Any) {
        MKMusicPlaybackHandler.play(memory: self.memory)
    }
}

