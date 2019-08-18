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
import SwiftVideoBackground

///`AlbumViewController`: displays the content and information about an album.
class AlbumViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var albumTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var statsView: UIView!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var dateAddedLabel: UILabel!
    @IBOutlet weak var playCountLabel: UILabel!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var contentWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?
        
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        self.settingsDidUpdate()
        
        //Register nib.
        let trackCell = UINib(nibName: "TrackTableViewCell", bundle: nil)
        self.tableView.register(trackCell, forCellReuseIdentifier: "track")
        
        //Setup video background.
        try? VideoBackground.shared.play(view: self.view, videoName: "onboarding", videoType: "mp4", isMuted: true, willLoopVideo: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //View background color.
        self.view.backgroundColor = .background

        ///Setup.
        self.setup()
        
    }
    
    var lastUpdatedWidth: CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.readableContentGuide.layoutFrame.width
        self.contentWidthConstraint.constant = width
        self.tableViewHeightConstraint.constant = 50.0 * CGFloat(self.album?.items.count ?? 0)
        self.view.layoutIfNeeded()
        
        
        //Scroll View content size.
        var height = width + 95.0
        height += (50.0 * CGFloat(self.album?.items.count ?? 0))
        height += self.statsView.frame.height + self.albumTitleLabel.frame.height + artistLabel.frame.height
        self.scrollView.contentSize = CGSize(width: 0, height: height)
    }
    
    //MARK: - Info view setup.
    func setup() {
        //Album artwork
        let width = self.view.frame.width
        DispatchQueue.global(qos: .userInteractive).async {
            let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width / 2))
            DispatchQueue.main.async {
                if self.artworkImageView != nil {
                    self.artworkImageView.image = artwork ?? UIImage(named: "logo500")
                }
            }
        }
        
        //Labels
        let representativeItem = self.album?.representativeItem
        self.albumTitleLabel.text = representativeItem?.albumTitle ?? ""
        self.artistLabel.text = representativeItem?.albumArtist ?? ""
        self.releaseDateLabel.text = representativeItem?.releaseDate?.shortString ?? "N/A"
        self.dateAddedLabel.text = representativeItem?.dateAdded.shortString
        self.songCountLabel.text = self.album?.items.count == 1 ? "1 Song" : "\(self.album?.items.count ?? 0) Songs"
        
        //Play Count
        DispatchQueue.global(qos: .userInteractive).async {
            var count = 0
            
            guard let album = self.album else { return }
            for item in album.items {
                count += item.playCount
            }
            DispatchQueue.main.async {
                self.playCountLabel.text = "\(count)"
            }
        }
        
        self.tableView.reloadData()
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        if #available(iOS 13.0, *) {
            
        }
        else {
            //Dark mode
            self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
            
            //View background color.
            self.view.backgroundColor = .background
            
            self.tableView.separatorColor = .secondaryText
            
            //Info view.
            self.albumTitleLabel.textColor = .navigationForeground
            self.releaseDateLabel.textColor = .text
            self.dateAddedLabel.textColor = .text
        }
    }
    
    @IBAction func openInAppleMusic(_ sender: Any) {
        
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.album?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Track
        let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        if let track = self.album?.items[indexPath.row] {
            cell.setup(withItem: track)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < self.album?.items.count ?? 0 {
            DispatchQueue.global().async {
                //Retrieve the array of songs starting at the selected index.
                let array = self.album?.items.subarray(startingAtIndex: indexPath.item)
                
                //Play the array of items.
                MKMusicPlaybackHandler.play(items: array ?? [])
            }
        }
    }
}
