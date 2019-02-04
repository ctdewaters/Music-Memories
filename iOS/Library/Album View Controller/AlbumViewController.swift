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
            self.iPhoneHeaderView.effect = Settings.shared.darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
            self.iPhoneAlbumTitleLabel.text = self.album?.representativeItem?.albumTitle ?? ""
            self.iPhoneAlbumArtistLabel.text = self.album?.representativeItem?.albumArtist ?? ""
            self.iPhoneArtworkImageView.layer.cornerRadius = 15
            self.iPhoneReleaseDateLabel.text = "Released \((self.album?.representativeItem?.releaseDate ?? Date()).shortString), Added \((self.album?.representativeItem?.dateAdded ?? Date()).shortString)"
            self.iPhoneCloseButton.tintColor = .theme


            //Set table view top inset.
            self.tableView.contentInset.top = self.iPhoneHeaderView.frame.height
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
        self.iPhoneHeaderView.effect = Settings.shared.darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
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
