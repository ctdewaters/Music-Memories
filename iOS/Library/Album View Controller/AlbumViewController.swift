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
    
    //MARK: - IBOutlet
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?

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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
}


extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return self.album?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
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
        if indexPath.section == 0 {
            return self.view.frame.width
        }
        return 50
    }
    
    //MARK: - Section header.
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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
        if section == 0 {
            return 0
        }
        if let height = self.album?.representativeItem?.albumTitle?.height(withConstrainedWidth: self.view.frame.width - 32, font: UIFont.systemFont(ofSize: 25, weight: .bold)) {
            return 115 + height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
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
