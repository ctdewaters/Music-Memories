//
//  HomeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

weak var homeVC: HomeViewController?

///`HomeViewController`: displays the user's memories, and provides access to memory creation and settings.
class HomeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //MARK: - Properties
    var retrievedMemories = [MKMemory]()
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    //MARK: - `UIViewController` overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set global variable.
        homeVC = self
        
        //Register for peek and pop.
        self.registerForPreviewing(with: self, sourceView: self.collectionView!)
        
        //Setup the navigation bar.
        self.setupNavigationBar()
        
        //Setup the collection view.
        self.setupCollectionView()
        
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveDeveloperToken), name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMusicUserToken), name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Navigation bar setup.
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        
        //Reload.
        self.reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
                
        //Check the application open settings for the create view
        if applicationOpenSettings?.openCreateView ?? false {
            applicationOpenSettings = nil
            self.performSegue(withIdentifier: "createMemory", sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Settings.didUpdateNotification, object: nil)
    }
    
    //MARK: - Setup functions.
    ///Sets up the navigation bar.
    private func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .themeColor
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        
        //Back button title (will show on pushed view controller).
        let barButtonItem = UIBarButtonItem()
        barButtonItem.title = "Home"
        self.navigationItem.backBarButtonItem = barButtonItem
        
        //Set title of this view controller.
        self.navigationItem.title = "Music Memories"
    }
    
    ///Sets up the collection view.
    private func setupCollectionView() {
        self.collectionView?.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.collectionView?.delegate = self
        self.collectionView?.contentInset.top = 10
        self.collectionView?.contentInset.left = 10
        self.collectionView?.contentInset.right = 10
        
        // Register cell classes
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.collectionView!.register(addMemoryNib, forCellWithReuseIdentifier: "addMemory")
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
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
            return cell
        }
        //Memory cell setup
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memory", for: indexPath) as! MemoryCell
        let thisMemory = retrievedMemories[indexPath.item - 1]
        cell.setup(withMemory: thisMemory)
        cell.state = Settings.shared.darkMode ? .dark : .light
        cell.indexPath = indexPath
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            return CGSize(width: self.view.frame.width - 20, height: 45)
        }
        return self.isPortrait() ? CGSize(width: (self.view.frame.width - 30) / 2, height:  (self.view.frame.width - 30) / 2) :
            CGSize(width: self.view.frame.width / 3 - 15, height: self.view.frame.width / 3 - 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
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
            self.performSegue(withIdentifier: "createMemory", sender: self)
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
            
            MemoryViewController.shared?.memory = self.retrievedMemories[indexPath.item - 1]
            self.navigationController?.pushViewController(MemoryViewController.shared!, animated: true)
        }
    }
    
    //MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    
        if segue.identifier == "createMemory" {
            
        }
    }
    
    //MARK: - Reloading
    func reload() {
        //Fetch the memories.
        self.retrievedMemories = MKCoreData.shared.fetchAllMemories().sorted {
            $0.startDate ?? Date().add(days: 0, months: 0, years: -999)! > $1.startDate ?? Date().add(days: 0, months: 0, years: -999)!
        }
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    //MARK: - Notification Center functions.
    @objc func didRecieveDeveloperToken() {
    }
    
    @objc func didRecieveMusicUserToken() {
        self.handleDynamicMemory()
    }
    
    //MARK: - Handling Dynamic Memory
    func handleDynamicMemory() {
        //Check if we have a dynamic memory (if setting is enabled).
        if Settings.shared.enableDynamicMemories {
            if let dynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                //Update the current dynamic memory.
                let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 15, maxAddsPerAlbum: 5)
                dynamicMemory.update(withSettings: updateSettings) { (success) in
                    DispatchQueue.main.async {
                        dynamicMemory.save()
                        self.reload()
                    }
                }
            }
            else {
                //Create new dynamic memory.
                if let newDynamicMemory = MKCoreData.shared.createNewDynamicMKMemory(withEndDate: Date().add(days: Settings.shared.dynamicMemoriesUpdatePeriod.days, months: 0, years: 0) ?? Date(), syncToLibrary: Settings.shared.addDynamicMemoriesToLibrary) {
                    //Update it.
                    let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 17, maxAddsPerAlbum: 5)
                    newDynamicMemory.update(withSettings: updateSettings) { (success) in
                        DispatchQueue.main.async {
                            newDynamicMemory.save()
                            newDynamicMemory.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .update)
                            
                            self.reload()
                        }
                    }
                }
            }
        }
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
    
    //MARK: Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
        
        UIView.animate(withDuration: 0.25) {
            self.collectionView?.backgroundColor = Settings.shared.darkMode ? .black : .white
        }
        
        //Reload collection view data.
        self.reload()
    }
}

//MARK: - `UIViewControllerPreviewingDelegate`.
extension HomeViewController: UIViewControllerPreviewingDelegate {
    
    //Peek
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Get the index path for the cell at the passed point.
        guard let indexPath = collectionView?.indexPathForItem(at: location), indexPath.item > 0 else {
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) else {
            return nil
            
        }
        
        //Set the shared memory view controller's memory property.
        MemoryViewController.shared?.memory = self.retrievedMemories[indexPath.item - 1]
        MemoryViewController.shared?.isPreviewing = true
        
        //Set the source rect.
        previewingContext.sourceRect = cell.frame
        
        return MemoryViewController.shared
    }
    
    //Pop
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        let vc = viewControllerToCommit as! MemoryViewController
        vc.isPreviewing = false
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    
}
