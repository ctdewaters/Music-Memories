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

///`AlbumViewController`: displays the content and information about an album.
class AlbumViewController: UIViewController {
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?

    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)

        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //View background color.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.navigationItem.title = self.album?.representativeItem?.albumTitle ?? ""
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
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
}
