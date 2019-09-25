//
//  MemoryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer
import SwiftVideoBackground
import Agrume

///`MemoryViewController`: A `MediaCollectionViewController` which displays and provides edit controls for a `MKMemory` object.
class MemoryViewController: MediaCollectionViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var showImagesButton: UIButton!
    
    
    //MARK: - Properties
    ///The memory to display.
    weak var memory: MKMemory?
            
    ///The memory images display view, which will display (and animate, if more than four) the images of the associated memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The thumbnail memory images display view.
    var thumbnailMemoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The blur animation property animator.
    var headerBlurPropertyAnimator: UIViewPropertyAnimator?
    
    static let reloadNotification = Notification.Name("memoryVCReload")
                
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup video background.
        VideoBackground.shared.removeVideoComposition()
        try? VideoBackground.shared.play(view: self.view, videoName: "onboarding", videoType: "mp4", isMuted: true, willLoopVideo: true)
        VideoBackground.shared.apply(orientation: .downMirrored)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.setup), name: MemoryViewController.reloadNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setup), name: MKCloudManager.didSyncNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        self.scrollView.contentInset.bottom = CDMiniPlayer.State.closed.size.height + 16.0

        self.setup()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Update memory images display view.
        self.memoryImagesDisplayView?.frame = self.artworkImageView.bounds
        self.memoryImagesDisplayView?.reload()
        
        self.tableViewHeightConstraint.constant += 8
        self.view.layoutIfNeeded()
                
        //Scroll View content size.
        let width = self.view.readableContentGuide.layoutFrame.width
        var height = width + 95.0
        height += (self.tableViewRowHeight * CGFloat(self.items.count))
        height += 56.0 + self.titleLabel.frame.height + self.subtitleLabel.frame.height + self.descriptionTextView.frame.height
        self.scrollView.contentSize = CGSize(width: 0, height: height)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    //MARK: - Setup
    @objc func setup() {
        DispatchQueue.main.async {
            //Set the items array with the memory's items.
            if let memoryItems = self.memory?.mpMediaItems {
                self.items = memoryItems.sorted {
                    return $0.playCount > $1.playCount
                }
            }
            
            //Setup table view properties.
            self.tableViewRowHeight = 60.0
            self.displaySetting = .artwork
            self.showSubtitle = true
            
            //Labels.
            self.titleLabel.text = self.memory?.title ?? ""
            self.navBarTitleLabel.text = self.titleLabel.text
            self.descriptionTextView.contentInset = UIEdgeInsets.zero
            self.descriptionTextView.text = self.memory?.desc
            
            if self.items.count == 1 {
                self.songCountLabel.text = "1 Song"
            }
            else {
                self.songCountLabel.text = "\(self.items.count) Songs"
            }
            
            //Date range.
            if let startDate = self.memory?.startDate, let endDate = self.memory?.endDate {
                self.subtitleLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
            }
            else {
                if let startDate = self.memory?.startDate {
                    self.subtitleLabel.text = startDate.longString
                }
                else if let endDate = self.memory?.endDate {
                    self.subtitleLabel.text = endDate.longString
                }
            }
            
            //Setup the memory images.
            self.setupMemoryImagesDisplayView()
            
            self.tableView.reloadData()
        }
    }
    
    ///Sets up the memory images display view.
    private func setupMemoryImagesDisplayView() {
        guard let memory = self.memory else { return }

        //Setup the main image display view.
        if self.memoryImagesDisplayView == nil {
            //Add the images display view to the images holding view.
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: self.artworkImageView.bounds)
            self.artworkImageView.addSubview(self.memoryImagesDisplayView!)

            //Center it.
            self.memoryImagesDisplayView?.center = CGPoint(x: self.artworkImageView.bounds.width / 2, y: (self.artworkImageView.bounds.height / 2))
        }
        
        //Setup the thumbnail.
        if self.thumbnailMemoryImagesDisplayView == nil && (self.memory?.images?.count ?? 0) > 0 {
            self.thumbnailMemoryImagesDisplayView = MemoryImagesDisplayView(frame: self.navBarTitleImage.bounds)
            self.navBarTitleImage.addSubview(self.thumbnailMemoryImagesDisplayView!)
        }
        
        self.memoryImagesDisplayView?.set(withMemory: memory)
        self.thumbnailMemoryImagesDisplayView?.set(withMemory: memory)
    }
    
    //MARK: - IBActions
    @IBAction func play(_ sender: Any) {
        MKMusicPlaybackHandler.play(items: self.items)
    }
    
    @IBAction func edit(_ sender: Any) {
        //Instantiate the initial VC of the edit storyboard and present it.
        guard let navigationController = editMemoryStoryboard.instantiateInitialViewController() as? UINavigationController, let vc = navigationController.viewControllers.first as? EditMemoryViewController else { return }
        vc.memory = self.memory
        self.present(navigationController, animated: true, completion: nil)
    }
    
    override func close(_ sender: Any) {
        super.close(sender)
        memoriesViewController?.updateMiniPlayerPadding()
    }
    
    @IBAction func showImages(_ sender: Any) {
        guard let memoryImages = self.memoryImagesDisplayView?.memoryImages else { return }
        
        let agrumeVC = AgrumeViewController()
        agrumeVC.modalPresentationStyle = .overFullScreen
        agrumeVC.view.backgroundColor = .clear
        self.present(agrumeVC, animated: false, completion: nil)
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: nil)
        closeButton.tintColor = .theme
        let agrume = Agrume(images: memoryImages, startIndex: 0, background: .blurred(.systemThickMaterialDark), dismissal: Dismissal.withPhysicsAndButton(closeButton))
        agrume.didDismiss = {
            agrumeVC.dismiss(animated: false, completion: nil)
        }

        agrume.show(from: agrumeVC)
        
    }
    
    @IBAction func highlightButton(_ sender: Any) {
        self.showImagesButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    @IBAction func unhighlightButton(_ sender: Any) {
        self.showImagesButton.backgroundColor = .clear
    }
    
    //MARK: - DateIntervalFormatter
    ///Creates and interval string using a start and end date.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
}

extension VideoBackground {
    func apply(orientation: CGImagePropertyOrientation) {
        //Retrieve the player item from the player layer.
        guard let playerItem = self.playerLayer.player?.currentItem else { return }
        playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
            request.finish(with: request.sourceImage.oriented(orientation), context: nil)
        }
    }
}

class AgrumeViewController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
