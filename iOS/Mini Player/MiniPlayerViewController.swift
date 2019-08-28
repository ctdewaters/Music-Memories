//
//  MiniPlayerViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/28/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

/// `MiniPlayerViewController`: Provides playback controls for currently playing song.
class MiniPlayerViewController: UIViewController {
    
    ///The window to present the miniplayer in.
    var window: UIWindow? {
        return UIWindow.key
    }
    
    ///The shared instance.
    public static let shared = MiniPlayerViewController()
    
    //MARK: - Initialization
    init() {
        super.init(nibName: "MiniPlayerViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
