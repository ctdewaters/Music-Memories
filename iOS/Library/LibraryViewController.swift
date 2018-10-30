//
//  LibraryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/30/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

///`LibraryViewController`: displays the user's music library by added date.
class LibraryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.tintColor = .theme
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Navigation bar setup.
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        self.hideHairline()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Reset navigation bar.
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
    
    //MARK: Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
    }
}
