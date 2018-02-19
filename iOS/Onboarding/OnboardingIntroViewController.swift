//
//  OnboardingIntroViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

class OnboardingIntroViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    
    //MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.nextButton.layer.cornerRadius = 10
        self.nextButton.backgroundColor = .themeColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func next(_ sender: Any) {
    }
    
}
