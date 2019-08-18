//
//  OnboardingVideoBackgroundViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/3/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import SwiftVideoBackground

class OnboardingVideoBackgroundViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        try? VideoBackground.shared.play(view: self.view, videoName: "onboarding", videoType: "mp4", isMuted: true, darkness: 0.25, willLoopVideo: true)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.performSegue(withIdentifier: "initOnboarding", sender: self)
    }
    
}
