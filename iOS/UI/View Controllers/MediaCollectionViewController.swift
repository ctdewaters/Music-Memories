//
//  MediaCollectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/19/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

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
    @IBOutlet weak var navBarTitleImage: UIImageView!
    @IBOutlet weak var navBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var navBarCloseButtonLeadingConstraint: NSLayoutConstraint!
    
    //MARK: - Properties
    ///If true, the nav bar is opened.
    private var navBarIsOpen = false

    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set scroll view delegate.
        self.scrollView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.readableContentGuide.layoutFrame.width
        self.contentWidthConstraint.constant = width
        self.navBarCloseButtonLeadingConstraint.constant = (self.view.frame.width - width) / 2
        self.view.layoutIfNeeded()        
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
            self.navBarTopConstraint.constant = -65
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
