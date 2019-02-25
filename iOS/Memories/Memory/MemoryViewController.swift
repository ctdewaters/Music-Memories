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
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
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
    
    ///If true, this view controller was just committed from a preview.
    var committedFromPreview = false
    
    ///The shared instance.
    public static var shared = mainStoryboard.instantiateViewController(withIdentifier: "memoryVC") as? MemoryViewController
    
    //MARK: - Resetting.
    public class func reset() {
        //Remove notification center observers.
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: AppDelegate.didBecomeActiveNotification, object: nil)

        //Reset the memory collection view.
        if let memoryCollectionView = MemoryViewController.shared?.memoryCollectionView {
            memoryCollectionView.memory = nil
            memoryCollectionView.itemsArray = nil
            memoryCollectionView.scrollCallback = nil
        }
        
        //Remove the memory images display view.
        MemoryViewController.shared?.memoryImagesDisplayView?.removeFromSuperview()
        MemoryViewController.shared?.memoryImagesDisplayView = nil
        
        //Set the memory to nil.
        MemoryViewController.shared?.memory = nil

        MemoryViewController.shared = nil
        MemoryViewController.shared = mainStoryboard.instantiateViewController(withIdentifier: "memoryVC") as? MemoryViewController
    }
    
    //MARK: - Header Buttons.
    //Sets up the header buttons.
    private func setupHeaderButtons() {
        //Setup header buttons.
        self.playButton.isHidden = false
        self.editButton.isHidden = false
        
        //Background color.
        self.playButton.backgroundColor = .white
        self.editButton.backgroundColor = .white
        
        //Corner radius.
        self.playButton.layer.cornerRadius = 10
        self.editButton.layer.cornerRadius = 10
        
        //Tint color.
        self.playButton.tintColor = .theme
        self.editButton.tintColor = .theme
        
        //Title color.
        self.playButton.setTitleColor(.theme, for: .normal)
        self.editButton.setTitleColor(.theme, for: .normal)
        
        //Set play button image content mode.
        self.playButton.imageView?.contentMode = .scaleAspectFit
        
        //Targets.
        self.playButton.addTarget(self, action: #selector(self.highlight(headerButton:)), for: .touchDown)
        self.playButton.addTarget(self, action: #selector(self.highlight(headerButton:)), for: .touchDragEnter)
        self.editButton.addTarget(self, action: #selector(self.highlight(headerButton:)), for: .touchDown)
        self.editButton.addTarget(self, action: #selector(self.highlight(headerButton:)), for: .touchDragEnter)
        self.playButton.addTarget(self, action: #selector(self.unhighlight(headerButton:)), for: .touchDragExit)
        self.editButton.addTarget(self, action: #selector(self.unhighlight(headerButton:)), for: .touchDragExit)
    }
    
    ///Highlights a header button.
    @objc private func highlight(headerButton button: UIButton) {
        button.alpha = 0.75
    }
    
    ///Unhighlight header button.
    @objc private func unhighlight(headerButton button: UIButton) {
        button.alpha = 1
    }

    @IBAction func headerButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            self.unhighlight(headerButton: button)
            
            if button == self.playButton {
                //Play button.
                //Play the whole memory.
                if self.memory != nil {
                    MKMusicPlaybackHandler.play(memory: self.memory!)
                }
            }
            else {
                //Edit button.
                if !self.memoryCollectionView.isEditing {
                    //Change to edit persona.
                    self.memoryCollectionView.enableEditing(toOn: true)
                    self.editButton.setTitle("Done", for: .normal)
                    self.editButton.backgroundColor = .success
                    self.editButton.setTitleColor(.white, for: .normal)
                    return
                }
                self.memoryCollectionView.enableEditing(toOn: false)
                self.editButton.setTitle("Edit", for: .normal)
                self.editButton.backgroundColor = .white
                self.editButton.setTitleColor(.theme, for: .normal)
            }
        }
    }
    
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register for peek and pop.
        self.registerForPreviewing(with: self, sourceView: self.memoryCollectionView!)
        
        //Set the max and min header height values.
        self.minimumHeaderHeight = (Device() == .iPhoneX ? 30 : 20) + 120
        self.maximumHeaderHeight = (Device() == .iPhoneX ? 30 : 20) + self.view.frame.width

        // Do any additional setup after loading the view.
        self.memoryCollectionView.set(withMemory: self.memory)
        self.memoryCollectionView.scrollCallback = { offset in
            self.collectionViewDidScroll(withOffset: offset)
        }
        
        //Header blur property animator.
        if self.headerBlurPropertyAnimator == nil && !self.isPreviewing {
            self.headerBlur.effect = nil
            self.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.headerBlur.effect = Settings.shared.blurEffect
            }
        }
        else {
            self.headerBlur.effect = nil
        }
        
        //Set title.
        self.titleTextView.text = self.memory.title ?? ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Determine the background color of the memory collection view.
        self.memoryCollectionView.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Set the content inset of the collection view.
        self.contentInset = self.maximumHeaderHeight - (Device() == .iPhoneX ? 35 : 20) - 95
        self.memoryCollectionView.contentInset.top = contentInset
                
        //Update now playing UI state.
        self.memoryCollectionView.updateNowPlayingUIState()
        
        //Setup memory images display view.
        if self.memoryImagesDisplayView == nil {
            self.setupMemoryImagesDisplayView()
        }
        
        if self.isPreviewing {
            //Set the header buttons as hidden, and scroll to the top of the collection view.
            self.playButton.isHidden = true
            self.editButton.isHidden = true
            
            self.memoryCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
        else {
            self.setupHeaderButtons()
        }
        
        //Header blur property animator.
        if self.headerBlurPropertyAnimator == nil && !self.isPreviewing {
            self.headerBlur.effect = nil
            self.headerBlurPropertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
                self.headerBlur.effect = Settings.shared.blurEffect
            }
        }
        
        //Add observer for MPMediaItemDidChange.
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemDidChange), name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.nowPlayingItemStateDidChange), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
                                
        //Light status bar style.
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Return status bar style to the current setting.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
                
        //Remove the header blur property animator.
        self.headerBlurPropertyAnimator?.startAnimation()
        self.headerBlurPropertyAnimator?.stopAnimation(false)
        self.headerBlurPropertyAnimator?.finishAnimation(at: .current)
        self.headerBlurPropertyAnimator = nil
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
            self.memoryImagesDisplayView?.set(withMemory: self.memory)
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

extension MemoryViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Get the index path for the cell at the passed point.
        guard let indexPath = self.memoryCollectionView?.indexPathForItem(at: location) else {
            return nil
        }
        
        //Check if the index path is in the items section.
        if indexPath.section != self.memoryCollectionView.itemsSection {
            return nil
        }
        
        guard let cell = self.memoryCollectionView?.cellForItem(at: indexPath) else {
            return nil
        }

        
        let propertiesVC = MemoryItemPropertiesViewController(nibName: "MemoryItemPropertiesViewController", bundle: nil)
        previewingContext.sourceRect = cell.frame
        propertiesVC.memoryItem = self.memoryCollectionView.items[indexPath.item]
        
        self.isPreviewing = true
        
        return propertiesVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let viewController = viewControllerToCommit as? MemoryItemPropertiesViewController {
            viewController.showButtons()
            viewController.contentTopConstraint.constant = -35
            self.navigationController?.show(viewController, sender: nil)
            self.isPreviewing = false
        }
    }
}
