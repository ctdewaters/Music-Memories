//
//  SettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import SwiftUI

class SettingsViewController: UIHostingController<SettingsView> {

    required init?(coder aDecoder: NSCoder) {
        super.init(rootView: SettingsView())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

