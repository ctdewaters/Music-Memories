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

weak var memoriesViewController: MemoriesViewController?

///`MemoriesViewController`: displays the user's memories, and provides access to memory creation and settings.
class MemoriesViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    //MARK: - Properties
    ///Memories retrieved from the Core Data model that will be displayed in the collection view.
    var retrievedMemories = [MKMemory]()
    
    ///The previously updated width, retrieved in `viewDidLayoutSubviews`.
    var previousWidth: CGFloat?
    
    ///The selected memory.
    private var selectedMemory: MKMemory?
    
    private var previewedMemoryVC: MemoryViewController?
    
    static let reloadNotification = Notification.Name("memoriesVCReload")

    //MARK: - IBOutlets.
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewContainerView: UIView!
    @IBOutlet weak var createMemoryButton: UIButton!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    
    //MARK: - `UIViewController` overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set global variable.
        memoriesViewController = self
                
        //Request permission to send notifications.
        AppDelegate.registerForNotifications { (allowed) in
            print(allowed)
            
            AppDelegate.retrieveNotificationSettings(withCompletion: { (settings) in
                
            })
        }
        
        //Setup the miniplayer.
        CDMiniPlayerController.shared.setup()
                                
        //Setup the nav bar and collection view.
        self.setupNavigationBar()
        self.setupCollectionView()
        self.hideHairline()
                        
        //Create memory button setup.
        self.createMemoryButton.frame.size = CGSize.square(withSideLength: 35)
        self.createMemoryButton.cornerRadius = 35/2
                
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveDeveloperToken), name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMusicUserToken), name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reload), name: MemoriesViewController.reloadNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.safeReload), name: MKCloudManager.didSyncNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleDynamicMemory), name: MKCloudManager.readyForDynamicUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.safeReload), name: MemoryViewController.reloadNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIWindow.key?.rootViewController = self.tabBarController
                        
        //Reload.
        self.safeReload()
        self.previousWidth = self.view.frame.width
        
        //Update the mini player's padding.
        self.updateMiniPlayerPadding()
        
        //Check the application open settings for the create view
        if applicationOpenSettings?.openCreateView ?? false {
            applicationOpenSettings = nil
            self.createMemory(self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let previousWidth = self.previousWidth else { return }
        
        //Reload the collection view to update cell sizing if the width has changed.
        if self.view.frame.width != previousWidth {
            self.collectionView.reloadData()
            self.previousWidth = self.view.frame.width
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "openMemory" {
            if let destination = segue.destination as? MemoryViewController {
                destination.memory = self.selectedMemory
                destination.isPreviewed = false
                destination.presentationController?.delegate = self
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Setup functions
    ///Sets up the navigation bar.
    internal override func setupNavigationBar() {
        super.setupNavigationBar()
        
        //Back button title (will show on pushed view controller).
        let barButtonItem = UIBarButtonItem()
        barButtonItem.title = "Home"
        self.navigationItem.backBarButtonItem = barButtonItem
        
        //Set title of this view controller.
        self.navigationItem.title = "Memories"
    }
    
    ///Sets up the collection view.
    private func setupCollectionView() {
        self.collectionView?.delegate = self
        self.collectionView?.contentInset.top = 10
        self.collectionView?.contentInset.left = 8
        self.collectionView?.contentInset.right = 8
        self.collectionView.contentInset.bottom = CDMiniPlayer.State.closed.size.height + 16.0
        
        // Register cell classes
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
    }
    
    //MARK: - Alerts
    private func setupAlertUI() {
        var requiresAlert = false
        var requiresButton = false
        
        if self.retrievedMemories.count == 0 {
            let titleFont = UIFont(name: "SFProRounded-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20)
            let subtitleFont = UIFont(name: "SFProRounded-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
            let text = NSMutableAttributedString(string: "You've created no memories!", attributes: [NSAttributedString.Key.foregroundColor : UIColor.theme, NSAttributedString.Key.font : titleFont])
            let subtitle = NSAttributedString(string: "\nCreate one by tapping the \"+\" button in the upper right corner.", attributes: [NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel, NSAttributedString.Key.font : subtitleFont])
            text.append(subtitle)
            alertLabel.attributedText = text
            requiresAlert = true
        }
        
        if !MKAuth.allowedLibraryAccess {
            alertLabel.text = "Music Memories requires access to your music library for creating and listening to memories."
            requiresAlert = true
            requiresButton = true
        }
                
        self.alertLabel.isHidden = !requiresAlert
        self.openSettingsButton.isHidden = !requiresButton
        self.createMemoryButton.isHidden = requiresButton
        self.collectionView.isHidden = requiresAlert
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
        cell.indexPath = indexPath
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let memory = self.retrievedMemories[indexPath.item]
        return MemoryCell.size(forCollectionViewWidth: collectionView.frame.width, andMemory: memory)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedMemory = self.retrievedMemories[indexPath.item]
        self.performSegue(withIdentifier: "openMemory", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    //MARK: - `UIContextMenu` Support
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let memory = self.retrievedMemories[indexPath.item]
        
        return self.contextMenuConfig(withMemory: memory)
    }
    
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            guard let vc = self.previewedMemoryVC else { return }
            vc.isPreviewed = false
            vc.presentationController?.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
        
    private func contextMenuConfig(withMemory memory: MKMemory) -> UIContextMenuConfiguration {
        let previewProvider = { () -> UIViewController? in
            guard let vc = mainStoryboard.instantiateViewController(identifier: "memoryVC") as? MemoryViewController else { return nil}
            
            self.previewedMemoryVC = vc
            vc.memory = memory
            vc.isPreviewed = true
            vc.presentationController?.delegate = self
            
            return vc
        }
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (actions) -> UIMenu? in
            // Creating delete button
            let play = UIAction(title: "Play", image: UIImage(systemName: "play.fill"), identifier: .none, discoverabilityTitle: nil, attributes: [], state: .off) { (action) in
                MKMusicPlaybackHandler.play(memory: memory)
            }
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash.circle"), identifier: .none, discoverabilityTitle: nil, attributes: .destructive, state: .off) { (action) in
                //Delete the memory.
                memory.delete()
                                                
                //Reload the home view controller.
                self.reload()
            }
            
            
            // Creating main context menu
            return UIMenu(title: "", image: UIImage(named: "logo100"), identifier: .none, options: .displayInline, children: [play, delete])
        }
        return config
    }
    
    //MARK: - Reloading
    /// Reloads the collection view.
    @objc func reload() {
        //Fetch the memories.
        self.retrievedMemories = MKCoreData.shared.fetchAllMemories().sorted {
            $0.startDate ?? Date().add(days: 0, months: 0, years: -999)! > $1.startDate ?? Date().add(days: 0, months: 0, years: -999)!
        }
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
            
            //Update the UI with the current permissions.
            self.setupAlertUI()
        }
    }
    
    /// Reloads the collection view obly if new memories are present.
    @objc func safeReload() {
        let visibleCells = self.collectionView.visibleCells
        DispatchQueue.global(qos: .userInteractive).async {
                        
            //Fetch the memories.
            let newMemories = MKCoreData.shared.fetchAllMemories().sorted {
                $0.startDate ?? Date().add(days: 0, months: 0, years: -999)! > $1.startDate ?? Date().add(days: 0, months: 0, years: -999)!
            }
            
            let deletedIndices = self.retrievedMemories.filter { !newMemories.contains($0) }.map { self.retrievedMemories.firstIndex(of: $0) }.filter { $0 != nil }.map { $0! }
            let addedIndices = newMemories.filter{ !self.retrievedMemories.contains($0) }.map { newMemories.firstIndex(of: $0) }.filter { $0 != nil }.map { $0! }
            
            let deletedIPs = deletedIndices.map { IndexPath(item: $0, section: 0) }
            let addedIPs = addedIndices.map { IndexPath(item: $0, section: 0) }
            
            self.retrievedMemories = newMemories
            
            DispatchQueue.main.async {
                for cell in visibleCells {
                    if let cell = cell as? MemoryCell, let memory = cell.memory {
                        cell.setup(withMemory: memory)
                    }
                }
                
                if deletedIPs.count > 0 || addedIPs.count > 0 {
                    //Update the UI with the current permissions.
                    self.setupAlertUI()

                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: deletedIPs)
                        self.collectionView.insertItems(at: addedIPs)
                    }, completion: nil)
                }
            }
        }
    }

    
    //MARK: - Notification Center functions.
    @objc func didRecieveDeveloperToken() {
    }
    
    @objc func didRecieveMusicUserToken() {
        if !MKAuth.isAuthenticated {
            self.handleDynamicMemory()
        }
    }
    
    //MARK: - Handling Dynamic Memory
    @objc func handleDynamicMemory() {
        DispatchQueue.global(qos: .background).async {
            //Check if we have a dynamic memory (if setting is enabled).
            if Settings.shared.dynamicMemoriesEnabled {
                
                let recentlyAddedUpdateSettings = MKMemory.UpdateSettings(heavyRotation: false, recentlyPlayed: false, recentlyAdded: true, playCount: 5, maxAddsPerAlbum: 15)
                let recentlyPlayedUpdateSettings = MKMemory.UpdateSettings(heavyRotation: false, recentlyPlayed: true, recentlyAdded: false, playCount: 20, maxAddsPerAlbum: 7)
                
                if let dynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() ?? MKCoreData.shared.createNewDynamicMKMemory(withEndDate: Date().add(days: Settings.shared.dynamicMemoriesUpdatePeriod.days, months: 0, years: 0) ?? Date(), syncToLibrary: Settings.shared.addDynamicMemoriesToLibrary) {
                    
                    dynamicMemory.settings?.updateWithAppleMusic = Settings.shared.addDynamicMemoriesToLibrary
                    
                    //Check if this memory has a notification scheduled.
                    if AppDelegate.lastDynamicNotificationID != dynamicMemory.storageID {
                        //Memory does not have a notification scheduled, schedule one with the AppDelegate.
                        AppDelegate.schedule(localNotificationWithContent: dynamicMemory.notificationContent, withIdentifier: "dynamicMemoryReminder", andSendDate: dynamicMemory.endDate ?? Date())
                        //Update the last dynamic notification id property of the AppDelegate.
                        AppDelegate.lastDynamicNotificationID = dynamicMemory.storageID
                    }
                    
                    //Update the current dynamic memory.
                    dynamicMemory.update(withSettings: recentlyAddedUpdateSettings) { (success) in
                        DispatchQueue.main.async {
                            dynamicMemory.save(sync: true, withAPNS: false)
                            self.safeReload()
                        }
                    }
                    dynamicMemory.update(withSettings: recentlyPlayedUpdateSettings) { (success) in
                        DispatchQueue.main.async {
                            dynamicMemory.save(sync: true, withAPNS: true)
                            self.safeReload()
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
    
    //MARK: - Miniplayer Padding
    func updateMiniPlayerPadding() {
        //Update the mini player's padding.
        let padding = self.tabBarController?.tabBar.frame.height ?? 0
        self.updateMiniPlayerWithPadding(padding: padding)
    }
    
    //MARK: - IBActions
    ///Signals to show the create memory view.
    @IBAction func createMemory(_ sender: Any) {
        guard let initialVC = memoryCreationStoryboard.instantiateInitialViewController() as? UINavigationController else { return }
        initialVC.view.layer.zPosition = CGFloat.greatestFiniteMagnitude
        self.present(initialVC, animated: true, completion: nil)
    }
    
    @IBAction func openSettings(_ sender: Any) {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.barStyle = .default
            self.tabBarController?.tabBar.barStyle = .default
            
            //Reload collection view data.
            self.reload()
        }
    }
}

extension MemoriesViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        //Update the mini player's padding.
        self.updateMiniPlayerPadding()
    }
}
