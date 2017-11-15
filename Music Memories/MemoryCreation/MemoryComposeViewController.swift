//
//  MemoryComposeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryComposeViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.titleLabel.textColor = Settings.shared.textColor
        self.subtitleLabel.textColor = Settings.shared.accessoryTextColor
        self.backgroundBlur.effect = Settings.shared.blurEffect
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
