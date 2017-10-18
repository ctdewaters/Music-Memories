//
//  HomeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class HomeViewController: UICollectionViewController {
    
    //MARK: - Properties
    var retrievedMemories = [MKMemory]()
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    //MARK: - View loading
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.collectionView!.register(addMemoryNib, forCellWithReuseIdentifier: "addMemory")
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        let deviceName = UIDevice.current.name
        if let userFirstName = deviceName.components(separatedBy: " ").first {
            navigationItem.title = "Hello, \(userFirstName)!"
        }
        else {
            navigationItem.title = "Hello!"
        }
        
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveDeveloperToken), name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMusicUserToken), name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var lastOrientationUpdateWasPortrait: Bool?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Check if we need to update the layout.
        if self.lastOrientationUpdateWasPortrait == nil || self.lastOrientationUpdateWasPortrait != self.isPortrait() {
            print("CHANGING")
            //Create the layout object.
            let layout = NFMCollectionViewFlowLayout()
            layout.equallySpaceCells = true
            //Set the item size.
            layout.itemSize = self.isPortrait() ? CGSize(width: self.view.frame.width / 2 - 20, height: self.view.frame.width / 2 - 20) :
                CGSize(width: self.view.frame.width / 3 - 30, height: self.view.frame.width / 3 - 30)
            self.collectionView?.setCollectionViewLayout(layout, animated: false)
        
            self.collectionView?.contentOffset = CGPoint(x: 0, y: -130)
        }
        lastOrientationUpdateWasPortrait = self.isPortrait()
    }
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + self.retrievedMemories.count
    }

    //Cell setup
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            //Setup the add memory cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "addMemory", for: indexPath) as! AddMemoryCell
            cell.state = .darkBlur
            return cell
        }
        //Memory cell setup
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memory", for: indexPath) as! MemoryCell
        let thisMemory = retrievedMemories[indexPath.item - 1]
        cell.setup(withMemory: thisMemory)
        cell.state = .dark
        return cell
    }
    
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    // MARK: UICollectionViewDelegate
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //Check if the highlighted cell is the add memory cell.
        if let cell = collectionView.cellForItem(at: indexPath) as? AddMemoryCell {
            cell.highlight()
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.highlight()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        //Check if the unhighlighted cell is the add memory cell.
        if let cell = collectionView.cellForItem(at: indexPath) as? AddMemoryCell {
            cell.removeHighlight()
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? AddMemoryCell {
            cell.removeHighlight()
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
        }
    }
    
    //MARK: - Reloading
    func reload() {
        self.retrievedMemories = MKCoreData.shared.fetchAllMemories()
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    //MARK: - Notification Center functions.
    @objc func didRecieveDeveloperToken() {
    }
    
    @objc func didRecieveMusicUserToken() {
    }
    
    //MARK: - Orientation function
    func isPortrait() -> Bool {
        if self.view.frame.width > self.view.frame.height {
            return false
        }
        return true
    }

    //MARK: - IBActions
    @IBAction func settingsButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "homeToSettings", sender: self)
    }
}
