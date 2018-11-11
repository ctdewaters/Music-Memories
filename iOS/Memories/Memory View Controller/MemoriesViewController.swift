//
//  HomeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import UserNotifications

weak var homeVC: MemoriesViewController?

///`MemoriesViewController`: displays the user's memories, and provides access to memory creation and settings.
class MemoriesViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properties
    ///Memories retrieved from the Core Data model that will be displayed in the collection view.
    var retrievedMemories = [MKMemory]()
    
    //MARK: - IBOutlets.
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewContainerView: UIView!
    
    //MARK: - `UIViewController` overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set global variable.
        homeVC = self
        
        //Request permission to send notifications.
        AppDelegate.registerForNotifications { (allowed) in
            print(allowed)
            
            AppDelegate.retrieveNotificationSettings(withCompletion: { (settings) in
                
            })
        }

        //Register for peek and pop.
        if self.traitCollection.forceTouchCapability == .available {
            self.registerForPreviewing(with: self, sourceView: self.collectionView!)
        }

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
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        self.hideHairline()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Reload.
        self.reload()
        
        //Reset navigation bar.
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
                
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
                
        //Check the application open settings for the create view
        if applicationOpenSettings?.openCreateView ?? false {
            applicationOpenSettings = nil
            self.performSegue(withIdentifier: "createMemory", sender: self)
        }
        
        //Reset the shared `MemoryViewController`.
        MemoryViewController.reset()
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
        self.navigationController?.navigationBar.tintColor = .theme
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        //Back button title (will show on pushed view controller).
        let barButtonItem = UIBarButtonItem()
        barButtonItem.title = "Home"
        self.navigationItem.backBarButtonItem = barButtonItem
        
        //Set title of this view controller.
        self.navigationItem.title = "Memories"
    }
    
    ///Sets up the collection view.
    private func setupCollectionView() {
        self.collectionView?.backgroundColor = .clear
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.collectionView?.delegate = self
        self.collectionView?.contentInset.top = 10
        self.collectionView?.contentInset.left = 10
        self.collectionView?.contentInset.right = 10
        self.collectionView.contentInset.bottom = 75
        
        // Register cell classes
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.retrievedMemories.count
    }

    //Cell setup
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //Memory cell setup
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memory", for: indexPath) as! MemoryCell
        let thisMemory = retrievedMemories[indexPath.item]
        cell.setup(withMemory: thisMemory)
        cell.state = Settings.shared.darkMode ? .dark : .light
        cell.indexPath = indexPath
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
   
        return self.isPortrait() ? CGSize.square(withSideLength:  (self.view.frame.width - 30) / 2) :
            CGSize.square(withSideLength: self.view.frame.width / 3 - 15)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //Check if the highlighted cell is the add memory cell.
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        //Check if the unhighlighted cell is the add memory cell.
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
            
            MemoryViewController.reset()
            MemoryViewController.shared?.memory = self.retrievedMemories[indexPath.item]
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
        if Settings.shared.dynamicMemoriesEnabled {
            //Fetch current dynamic memory.
            if let dynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                //Check if this memory has a notification scheduled.
                if AppDelegate.lastDynamicNotificationID != dynamicMemory.storageID {
                    //Memory does not have a notification scheduled, schedule one with the AppDelegate.
                    AppDelegate.schedule(localNotificationWithContent: dynamicMemory.notificationContent, withIdentifier: "dynamicMemoryReminder", andSendDate: dynamicMemory.endDate ?? Date())
                    //Update the last dynamic notification id property of the AppDelegate.
                    AppDelegate.lastDynamicNotificationID = dynamicMemory.storageID
                }
                
                //Update the current dynamic memory.
                let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 15, maxAddsPerAlbum: 5)
                dynamicMemory.update(withSettings: updateSettings) { (success) in
                    DispatchQueue.main.async {
                        dynamicMemory.save()
                        //self.reload()
                    }
                }
            }
            else {
                //No current Dynamic Memory, create a new one.
                if let newDynamicMemory = MKCoreData.shared.createNewDynamicMKMemory(withEndDate: Date().add(days: Settings.shared.dynamicMemoriesUpdatePeriod.days, months: 0, years: 0) ?? Date(), syncToLibrary: Settings.shared.addDynamicMemoriesToLibrary) {
                    
                    //Schedule a notification for it.
                    AppDelegate.schedule(localNotificationWithContent: newDynamicMemory.notificationContent, withIdentifier: "dynamicMemoryReminder", andSendDate: newDynamicMemory.endDate ?? Date())
                    //Update the last dynamic notification id property of the AppDelegate.
                    AppDelegate.lastDynamicNotificationID = newDynamicMemory.storageID
                    
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
    
    //MARK: - IBActions.
    ///Signals to show the create memory view.
    @IBAction func createMemory(_ sender: Any) {
        self.performSegue(withIdentifier: "createMemory", sender: self)
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle

        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
        
        UIView.animate(withDuration: 0.25) {
            self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        }
        
        //Reload collection view data.
        self.reload()
    }
}

//MARK: - `UIViewControllerPreviewingDelegate`.
extension MemoriesViewController: UIViewControllerPreviewingDelegate {
    
    //Peek
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Get the index path for the cell at the passed point.
        guard let indexPath = collectionView?.indexPathForItem(at: location) else {
            return nil
        }
        
        guard let cell = collectionView?.cellForItem(at: indexPath) else {
            return nil
            
        }
        
        //Reset the memory view controller.
        MemoryViewController.reset()
        
        //Set the shared memory view controller's memory property.
        MemoryViewController.shared?.memory = self.retrievedMemories[indexPath.item]
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
        vc.memoryCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .bottom, animated: false)
    }
}
