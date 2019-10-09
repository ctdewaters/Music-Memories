//
//  MediaCollectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer
import MemoriesKit

///`MediaCollectionViewController`: A superclass for `AlbumViewController` and `MemoryViewController`, providing common UI elements.
class MediaCollectionViewController: UIViewController, UIScrollViewDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurOverlayView: UIVisualEffectView!
    
    @IBOutlet weak var navBar: UIVisualEffectView!
    @IBOutlet weak var navBarTitleLabel: UILabel!
    @IBOutlet weak var navBarTitleImage: UIImageView!
    @IBOutlet weak var navBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var navBarCloseButtonLeadingConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    ///If true, the nav bar is opened.
    private var navBarIsOpen = false
    
    ///If true, this memory was opened with a context menu preview.
    var isPreviewed = false
    
    ///The media items to display.
    var items = [MPMediaItem]()
    
    var tableViewRowHeight: CGFloat = 50.0
    var displaySetting: TrackTableViewCell.DisplaySetting = .trackNumber
    var showSubtitle = false

    //MARK: - UIViewController Overrides
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register table view cell nib.
        let trackCell = UINib(nibName: "TrackTableViewCell", bundle: nil)
        self.tableView.register(trackCell, forCellReuseIdentifier: "track")

        //Set scroll view delegate.
        self.scrollView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.readableContentGuide.layoutFrame.width
        self.contentWidthConstraint.constant = width
        self.navBarCloseButtonLeadingConstraint.constant = (self.view.frame.width - width) / 2
        self.tableViewHeightConstraint.constant = self.tableViewRowHeight * CGFloat(self.items.count)
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Update the mini player's padding.
        if !self.isPreviewed {
            self.updateMiniPlayerWithPadding(padding: UIWindow.key?.safeAreaInsets.bottom ?? 0)
        }
    }

    //MARK: - Scroll View Delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            let yContentOffset = scrollView.contentOffset.y
            
            self.toggleNavBar(toOpen: yContentOffset > self.artworkImageView.frame.height)
        }
    }
    
    //MARK: - Nav Bar functions.
    private func toggleNavBar(toOpen open: Bool) {
        //Only close if the bar is currently in the open state.
        if !open && self.navBarIsOpen {
            self.navBarIsOpen = false
            //Close the bar.
            self.navBarTopConstraint.constant = -85
        }
        else if open && !self.navBarIsOpen {
            self.navBarIsOpen = true
            //Open the bar.
            self.navBarTopConstraint.constant = 0
        }
        
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

//MARK: - UITableViewDelegate & DataSource
extension MediaCollectionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Track
        let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        let track = self.items[indexPath.row]
        cell.setup(withItem: track, andDisplaySetting: self.displaySetting, showSubtitle: self.showSubtitle)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableViewRowHeight
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < self.items.count {
            DispatchQueue.global(qos: .background).async {
                //Retrieve the array of songs starting at the selected index.
                let itemsToPlay = self.items.subarray(startingAtIndex: indexPath.item)
                
                print(itemsToPlay.first?.title)
                
                //Play the array of items.
                MKMusicPlaybackHandler.play(items: itemsToPlay)
            }
        }
    }
}
