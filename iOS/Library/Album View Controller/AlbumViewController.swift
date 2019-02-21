//
//  AlbumViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import LibraryKit
import MediaPlayer
import MemoriesKit

///`AlbumViewController`: displays the content and information about an album.
class AlbumViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    //iPhone Outlets.
    @IBOutlet weak var iPhoneHeaderView: UIVisualEffectView!
    @IBOutlet weak var iPhoneAlbumArtistLabel: UILabel!
    @IBOutlet weak var iPhoneAlbumTitleLabel: UILabel!
    @IBOutlet weak var iPhoneArtworkImageView: UIImageView!
    @IBOutlet weak var iPhoneReleaseDateLabel: UILabel!
    @IBOutlet weak var iPhoneCloseButton: UIButton!
    @IBOutlet weak var iPhoneAlbumShadowView: UIView!
    
    //Constraint outlets.
    @IBOutlet weak var textTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var artworkCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTextCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var iPhoneHeaderHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var artistTextCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateTextCenterConstraint: NSLayoutConstraint!
    
    //iPad Outlets.
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var dateAddedLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var totalPlayCountTitleLabel: UILabel!
    @IBOutlet weak var playCountLabel: UILabel!
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?
    
    var isPad: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad && self.view.frame.width >= 678.0 {
            return true
        }
        return false
    }
    
    ///The maximum height for the iPhone header.
    var maxiPhoneHeaderHeight: CGFloat = 450
    
    ///The minimum height for the iPhone header.
    var miniPhoneHeaderHeight: CGFloat = 150
    
    ///The maximum height for the iPhone artwork.
    var maxiPhoneArtworkHeight: CGFloat = 0

    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        self.settingsDidUpdate()

        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
        
        //Register nibs.
        let artworkCell = UINib(nibName: "AlbumArtworkTableViewCell", bundle: nil)
        self.tableView.register(artworkCell, forCellReuseIdentifier: "artwork")
        let trackCell = UINib(nibName: "TrackTableViewCell", bundle: nil)
        self.tableView.register(trackCell, forCellReuseIdentifier: "track")
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //View background color.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        self.setupInfoView()
    }
    
    var lastUpdatedWidth: CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.lastUpdatedWidth == 0.0 || self.lastUpdatedWidth != self.view.frame.width {
            self.lastUpdatedWidth = self.view.frame.width
            self.tableView.reloadData()
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    //MARK: - Info view setup.
    func setupInfoView() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.infoView.layer.cornerRadius = 15
            self.artworkImageView.layer.cornerRadius = 15
            self.albumTitleLabel.text = self.album?.representativeItem?.albumTitle ?? ""
            self.genreLabel.text = self.album?.representativeItem?.genre ?? ""
            self.releaseDateLabel.text = "Released On \((self.album?.representativeItem?.releaseDate ?? Date()).medString)"
            self.dateAddedLabel.text = "Added On \((self.album?.representativeItem?.dateAdded ?? Date()).medString)"
            
            self.playCountLabel.backgroundColor = .theme
            self.playCountLabel.layer.cornerRadius = self.playCountLabel.frame.width / 2
            
            //Calculate total play count of all songs in background thread.
            DispatchQueue.global(qos: .userInitiated).async {
                var count = 0
                for item in self.album?.items ?? [] {
                    count += item.playCount
                }
                DispatchQueue.main.async {
                    self.playCountLabel.text = "\(count)"
                }
            }
        }
        if self.iPhoneHeaderView != nil {
            self.iPhoneHeaderView.effect = .none
            self.iPhoneHeaderView.backgroundColor = Settings.shared.darkMode ? .black : .white
            self.iPhoneAlbumTitleLabel.text = self.album?.representativeItem?.albumTitle ?? ""
            self.iPhoneAlbumArtistLabel.text = self.album?.representativeItem?.albumArtist ?? ""
            self.iPhoneArtworkImageView.layer.cornerRadius = 5
            self.iPhoneReleaseDateLabel.text = "Released \((self.album?.representativeItem?.releaseDate ?? Date()).shortString), Added \((self.album?.representativeItem?.dateAdded ?? Date()).shortString)"
            self.iPhoneCloseButton.tintColor = .theme
            self.maxiPhoneHeaderHeight = self.iPhoneHeaderView.frame.height
            self.maxiPhoneArtworkHeight = self.iPhoneArtworkImageView.frame.height

            //Set table view top inset.
            self.tableView.contentInset.top = self.iPhoneHeaderView.frame.height
            
            //Set text top constraint value.
            self.textTopConstraint.constant = self.iPhoneArtworkImageView.frame.height + 8
            self.iPhoneHeaderView.layoutIfNeeded()
        }
        
        //Album artwork.
        let width = self.view.frame.width
        DispatchQueue.global(qos: .userInitiated).async {
            let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width / 2))
            DispatchQueue.main.async {
                if self.artworkImageView != nil {
                    self.artworkImageView.image = artwork
                }
                if self.iPhoneArtworkImageView != nil {
                    self.iPhoneArtworkImageView.image = artwork
                }
            }
        }
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.iPhoneHeaderView.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.iPhoneAlbumTitleLabel.textColor = Settings.shared.darkMode ? .white : .theme
        self.iPhoneAlbumArtistLabel.textColor = Settings.shared.textColor
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        //View background color.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        self.tableView.separatorColor = Settings.shared.darkMode ? .gray : .theme
        
        //Info view.
        self.albumTitleLabel.textColor = Settings.shared.darkMode ? .white : .theme
        self.genreLabel.textColor = Settings.shared.textColor
        self.releaseDateLabel.textColor = Settings.shared.textColor
        self.dateAddedLabel.textColor = Settings.shared.textColor
        self.totalPlayCountTitleLabel.textColor = Settings.shared.textColor
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    @IBAction func openInAppleMusic(_ sender: Any) {
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        LibraryViewController.shared?.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //MARK: Scroll View functions.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //Calculate the offset ratio.
        let yOffset = scrollView.contentOffset.y + self.maxiPhoneHeaderHeight
        var offsetRatio = (yOffset / (self.maxiPhoneHeaderHeight - self.miniPhoneHeaderHeight))
        if offsetRatio > 1 {
            offsetRatio = 1
        }
        if offsetRatio < 0 {
            offsetRatio = 0
        }
        
        if self.iPhoneHeaderView != nil {
            //Artwork constraints.
            self.artworkHeightConstraint.constant = self.newArtworkHeight(withOffsetRatio: offsetRatio)
            self.artworkCenterConstraint.constant = self.newArtworkCenterOffset(withOffsetRatio: offsetRatio)
            
            //Text constraints.
            self.textTopConstraint.constant = self.newTopTextOffset(withOffsetRatio: offsetRatio)
            self.titleTextCenterConstraint.constant = self.newTextCenterOffset(forLabel: self.iPhoneAlbumTitleLabel, withOffsetRatio: offsetRatio)
            self.artistTextCenterConstraint.constant = self.newTextCenterOffset(forLabel: self.iPhoneAlbumArtistLabel, withOffsetRatio: offsetRatio)
            self.dateTextCenterConstraint.constant = self.newTextCenterOffset(forLabel: self.iPhoneReleaseDateLabel, withOffsetRatio: offsetRatio)
            
            //Text scaling
            let titleLabelScale = 1 - (0.15 * offsetRatio)
            self.iPhoneAlbumTitleLabel.font = UIFont.systemFont(ofSize: 25 * titleLabelScale, weight: .bold)
            self.iPhoneAlbumArtistLabel.font = UIFont.systemFont(ofSize: 16 * titleLabelScale, weight: .medium)
            
            //Artwork shadow.
            self.iPhoneAlbumShadowView.alpha = 1 - (0.5 * offsetRatio)
            
            //Header height constraint.
            self.iPhoneHeaderHeightConstraint.constant = self.maxiPhoneHeaderHeight - ((self.maxiPhoneHeaderHeight - self.miniPhoneHeaderHeight) * offsetRatio)
            
            //Layout new constraints.
            self.iPhoneHeaderView.layoutIfNeeded()
        }
    }
    
    ///Calculates a height for the artwork in the iPhone header, given an offset ratio.
    func newArtworkHeight(withOffsetRatio offsetRatio: CGFloat) -> CGFloat {
        let destination = self.miniPhoneHeaderHeight - 32
        return self.maxiPhoneArtworkHeight - ((self.maxiPhoneArtworkHeight - destination) * offsetRatio)
    }
    
    ///Calculates a x center offset for the artwork in the iPhone header, given an offset ratio.
    func newArtworkCenterOffset(withOffsetRatio offsetRatio: CGFloat) -> CGFloat {
        let destination = 16 + ((self.miniPhoneHeaderHeight - 32) / 2)
        let travelDistance = (self.view.frame.width / 2) - destination
        return -travelDistance * offsetRatio
    }
    
    ///Calculates a new top constraint constant for the text in the iPhone header, given an offset ratio.
    func newTopTextOffset(withOffsetRatio offsetRatio: CGFloat) -> CGFloat {
        let destination: CGFloat = -8
        let travelDistance = (self.maxiPhoneArtworkHeight + 8) - destination
        return travelDistance * (1 - offsetRatio)
    }
    
    func newTextCenterOffset(forLabel label: UILabel, withOffsetRatio offsetRatio: CGFloat) -> CGFloat {
        let destination = (self.view.frame.width / 2) - 16 - (label.frame.width / 2)
        return destination * offsetRatio
    }
}

extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.album?.items.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Track
        if indexPath.row < self.album?.items.count ?? 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
            if let track = self.album?.items[indexPath.row] {
                cell.setup(withItem: track)
            }
            return cell
        }
        
        let trackCount = self.album?.items.count ?? 0
        let cell = UITableViewCell(style: .default, reuseIdentifier: "trackCount")
        cell.textLabel?.text = trackCount == 1 ? "1 Track" : "\(trackCount) Tracks"
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        cell.textLabel?.textColor = .darkGray
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == self.album?.items.count ?? 0 {
            return 30
        }
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < self.album?.items.count ?? 0 {
            DispatchQueue.global().async {
                //Song selected, play array starting at that index.
                ///Retrieve the array of songs starting at the selected index.
                let array = self.album?.items.subarray(startingAtIndex: indexPath.item)
                
                MKMusicPlaybackHandler.play(items: array ?? [])
            }
        }
    }
}
