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
import MarqueeLabel

///`AlbumViewController`: displays the content and information about an album.
class AlbumViewController: UIViewController {
    
    //MARK: - IBOutlets
    ///The table view, displaying the tracks for the album, and other information.
    @IBOutlet weak var tableView: UITableView!
    
    //iPhone Outlets.
    ///The iPhone header view.
    @IBOutlet weak var iPhoneHeaderView: UIVisualEffectView!
    ///The iPhone header artist label.
    @IBOutlet weak var iPhoneAlbumArtistLabel: MarqueeLabel!
    ///The iPhone header album title label.
    @IBOutlet weak var iPhoneAlbumTitleLabel: MarqueeLabel!
    ///The iPhone header artwork image view.
    @IBOutlet weak var iPhoneArtworkImageView: UIImageView!
    ///The iPhone header release date label.
    @IBOutlet weak var iPhoneReleaseDateLabel: UILabel!
    ///The iPhone header album image view shadow view.
    @IBOutlet weak var iPhoneAlbumShadowView: UIView!
    
    //Constraint outlets.
    ///The top constraint for the text in the iPhone header view.
    @IBOutlet weak var textTopConstraint: NSLayoutConstraint!
    ///The height constraint for the artwork in the iPhone header view.
    @IBOutlet weak var artworkHeightConstraint: NSLayoutConstraint!
    ///The center constraint for the artwork in the iPhone header view.
    @IBOutlet weak var artworkCenterConstraint: NSLayoutConstraint!
    ///The title text center constraint in the iPhone header view.
    @IBOutlet weak var titleTextCenterConstraint: NSLayoutConstraint!
    //The height constraint for the iPhone header view.
    @IBOutlet weak var iPhoneHeaderHeightConstraint: NSLayoutConstraint!
    ///The artist text center constraint in the iPhone header view.
    @IBOutlet weak var artistTextCenterConstraint: NSLayoutConstraint!
    ///The date text center constraint in the iPhone header view.
    @IBOutlet weak var dateTextCenterConstraint: NSLayoutConstraint!
    
    //iPad Outlets.
    ///The image view that displays artwork for the album on iPads.
    @IBOutlet weak var artworkImageView: UIImageView!
    ///The iPad info view.
    @IBOutlet weak var infoView: UIView!
    ///The iPad album title label.
    @IBOutlet weak var albumTitleLabel: UILabel!
    ///The iPad release date label.
    @IBOutlet weak var releaseDateLabel: UILabel!
    ///The iPad date added label.
    @IBOutlet weak var dateAddedLabel: UILabel!
    ///The iPad genre label.
    @IBOutlet weak var genreLabel: UILabel!
    ///The iPad total play count title label.
    @IBOutlet weak var totalPlayCountTitleLabel: UILabel!
    ///The iPad play count label.
    @IBOutlet weak var playCountLabel: UILabel!
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?
        
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
        UIApplication.shared.statusBarStyle = .default
        
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
        self.view.backgroundColor = .systemBackground

        ///Setup the info and header views.
        self.setupInfoView()
    }
    
    var lastUpdatedWidth: CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.lastUpdatedWidth == 0.0 || self.lastUpdatedWidth != self.view.frame.width {
            self.lastUpdatedWidth = self.view.frame.width
            self.tableView.reloadData()
            
            ///Table view top content inset.
            if !self.isPad {
                self.tableView.contentInset.top = self.maxiPhoneHeaderHeight
            }
            else {
                self.tableView.contentInset.top = 0
            }
            self.tableView.contentInset.bottom = 16
            self.tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        }
    }
    
    //MARK: - Info view setup.
    func setupInfoView() {
        //Setup iPad header items.
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.infoView.layer.cornerRadius = 5
            self.artworkImageView.layer.cornerRadius = 5
            self.artworkImageView.backgroundColor = .systemBackground
            self.artworkImageView.tintColor = .theme
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
        
        //Setup iPhone header view.
        self.iPhoneHeaderView.effect = .none
        self.iPhoneHeaderView.backgroundColor = .systemBackground
        self.iPhoneAlbumTitleLabel.text = self.album?.representativeItem?.albumTitle ?? ""
        self.iPhoneAlbumArtistLabel.text = self.album?.representativeItem?.albumArtist ?? ""
        self.iPhoneArtworkImageView.layer.cornerRadius = 5
        self.iPhoneArtworkImageView.backgroundColor = .systemBackground
        self.iPhoneArtworkImageView.tintColor = .theme
        self.iPhoneReleaseDateLabel.text = "Released \((self.album?.representativeItem?.releaseDate ?? Date()).shortString), Added \((self.album?.representativeItem?.dateAdded ?? Date()).shortString)"
        self.maxiPhoneHeaderHeight = self.iPhoneHeaderView.frame.height + 8
        self.maxiPhoneArtworkHeight = self.iPhoneArtworkImageView.frame.height
        self.iPhoneAlbumShadowView.backgroundColor = .systemBackground
        
        //Set text top constraint value.
        self.textTopConstraint.constant = self.iPhoneArtworkImageView.frame.height + 8
        self.iPhoneHeaderView.layoutIfNeeded()
        
        //Album artwork.
        let width = self.view.frame.width
        DispatchQueue.global(qos: .userInitiated).async {
            let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width / 2))
            DispatchQueue.main.async {
                if self.artworkImageView != nil {
                    self.artworkImageView.image = artwork ?? UIImage(named: "logo500White")?.withRenderingMode(.alwaysTemplate)
                }
                if self.iPhoneArtworkImageView != nil {
                    self.iPhoneArtworkImageView.image = artwork ?? UIImage(named: "logo500White")?.withRenderingMode(.alwaysTemplate)
                }
            }
        }
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.iPhoneHeaderView.backgroundColor = .systemBackground
        self.iPhoneAlbumTitleLabel.textColor = .navigationForeground
        self.iPhoneAlbumArtistLabel.textColor = .label
        self.tabBarController?.tabBar.barStyle = .default
        
        //View background color.
        self.view.backgroundColor = .systemBackground
        
        self.tableView.separatorColor = .quaternaryLabel
        
        //Info view.
        self.albumTitleLabel.textColor = .navigationForeground
        self.genreLabel.textColor = .label
        self.releaseDateLabel.textColor = .label
        self.dateAddedLabel.textColor = .label
        self.totalPlayCountTitleLabel.textColor = .label
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = .default
    }
    
    @IBAction func openInAppleMusic(_ sender: Any) {
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
        
        print(offsetRatio)
        
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
           self.iPhoneAlbumTitleLabel.transform = CGAffineTransform(scaleX: titleLabelScale, y: titleLabelScale)
           self.iPhoneAlbumArtistLabel.transform = CGAffineTransform(scaleX: titleLabelScale, y: titleLabelScale)
           self.releaseDateLabel.transform = CGAffineTransform(scaleX: titleLabelScale, y: titleLabelScale)

            
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
        var destination = -self.view.frame.width / 2
        destination += self.miniPhoneHeaderHeight + (label.frame.width / 2)

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
