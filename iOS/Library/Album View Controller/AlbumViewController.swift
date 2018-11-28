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
        
        self.tableView.tableFooterView = UIView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //View background color.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.navigationItem.title = self.album?.representativeItem?.albumArtist ?? ""
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.setupInfoView()
        }
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

        
        //Album artwork.
        let width = self.view.frame.width
        DispatchQueue.global(qos: .userInitiated).async {
            let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width / 2))
            DispatchQueue.main.async {
                self.artworkImageView.image = artwork
            }
        }
    }
    
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
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
}

extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isPad {
            return 1
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && !self.isPad {
            return 1
        }
        return self.album?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && !self.isPad {
            //Artwork
            let cell = tableView.dequeueReusableCell(withIdentifier: "artwork") as! AlbumArtworkTableViewCell
            
            let width = self.view.frame.width
            DispatchQueue.global(qos: .userInitiated).async {
                let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width))
                DispatchQueue.main.async {
                    cell.artworkImageView.image = artwork
                }
            }
            return cell
        }
        //Track
        let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        if let track = self.album?.items[indexPath.row] {
            cell.setup(withItem: track)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && !self.isPad {
            return self.view.frame.width
        }
        return 50
    }
    
    //MARK: - Section header.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.isPad {
            return nil
        }
        
        if section == 0 {
            return nil
        }
        let header: AlbumSectionHeaderView = .fromNib()
        if let album = self.album {
            header.setup(withAlbum: album)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || self.isPad {
            return 0
        }
        if let height = self.album?.representativeItem?.albumTitle?.height(withConstrainedWidth: self.view.frame.width - 32, font: UIFont.systemFont(ofSize: 25, weight: .bold)) {
            return 115 + height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 || self.isPad {
            //Play the array.
            DispatchQueue.global().async {
                //Song selected, play array starting at that index.
                ///Retrieve the array of songs starting at the selected index.
                let array = self.album?.items.subarray(startingAtIndex: indexPath.item)
                
                MKMusicPlaybackHandler.play(items: array ?? [])
            }
        }
    }
    
}
