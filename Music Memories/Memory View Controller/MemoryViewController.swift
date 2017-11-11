//
//  MemoryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryViewController: UICollectionViewController {
    
    var memory: MKMemory!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.memoryCollectionView.set(withMemory: memory)
        
        //Set title.
        self.navigationItem.title = self.memory.title ?? ""
        self.navigationItem.backBarButtonItem?.title = "Back"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.memoryCollectionView.backgroundColor = Settings.shared.darkMode ? .black : .white
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var memoryCollectionView: MemoryCollectionView {
        return self.collectionView as! MemoryCollectionView
    }
    
}
