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

class HomeViewController: UICollectionViewController {
    
    //MARK: - Properties
    var retrievedMemories = [MKMemory]()
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    var blurUnderlay: UIVisualEffectView?
    var poppedViewController: MemorySettingsViewController?
    var actionView: MemorySettingsActionView?
    var poppedMemory: MKMemory?
    var poppedIndexPath: IndexPath?
    
    weak var selectedMemory: MKMemory?
    weak var selectedCell: MemoryCell?
    
    //MARK: - View loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set global variable.
        homeVC = self

        self.registerForPreviewing(with: self, sourceView: self.collectionView!)
        
        // Register cell classes
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.collectionView!.register(addMemoryNib, forCellWithReuseIdentifier: "addMemory")
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
        
        //Navigation bar setup.
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.tintColor = .themeColor
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.collectionView?.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Add settings did change notification observer.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        
        navigationItem.title = "Music Memories"
        
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveDeveloperToken), name: MKAuth.developerTokenWasRetrievedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didRecieveMusicUserToken), name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
        
        //Reload.
        self.reload()
        
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
    
    var lastOrientationUpdateWasPortrait: Bool?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Check if we need to update the layout.
        if self.lastOrientationUpdateWasPortrait == nil || self.lastOrientationUpdateWasPortrait != self.isPortrait() {
            //Create the layout object.
            let layout = NFMCollectionViewFlowLayout()
            layout.equallySpaceCells = true
            //Set the item size.
            layout.itemSize = self.isPortrait() ? CGSize(width: self.view.frame.width / 2 - 20, height: self.view.frame.width / 2 - 20) :
                CGSize(width: self.view.frame.width / 3 - 30, height: self.view.frame.width / 3 - 30)
            self.collectionView?.setCollectionViewLayout(layout, animated: false)
        
            let indexPath = IndexPath(item: 0, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
        }
        
        //Popped view controller
        blurUnderlay?.frame = self.view.frame
        poppedViewController?.view.frame.size.width = self.view.frame.width - 40
        poppedViewController?.view.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        poppedViewController?.view.frame.size.height = 103
        
        actionView?.frame.size = CGSize(width: poppedViewController?.view.frame.width ?? 0, height: MemorySettingsActionView.requiredHeight)
        actionView?.frame.origin.y = self.view.frame.height - 16 - MemorySettingsActionView.requiredHeight
        actionView?.center.x = self.view.frame.width / 2
        
        if actionView != nil && poppedViewController != nil && poppedViewController!.view.frame.contains(actionView!.frame.origin) {
            poppedViewController!.view.frame.origin.y = actionView!.frame.origin.y - 103 - 16
        }
        
        
        lastOrientationUpdateWasPortrait = self.isPortrait()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Settings.didUpdateNotification, object: nil)
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
        cell.state = Settings.shared.darkMode ? .dark : .light
        cell.indexPath = indexPath
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
            self.performSegue(withIdentifier: "createMemory", sender: self)
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryCell {
            cell.removeHighlight()
            
            self.selectedCell = cell
            self.selectedMemory = self.retrievedMemories[indexPath.item - 1]
            self.performSegue(withIdentifier: "openMemory", sender: self)
        }
    }
    
    //MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    
        if segue.identifier == "openMemory" {
            //Setup the memory view controller.
            
            let segue = segue as! MemorySegue
            segue.back = false
            segue.sourceFrame = collectionView?.convert(self.selectedCell!.frame, to: self.view.superview!) ?? .zero
            
            let destinationVC = segue.destination as! MemoryViewController
            destinationVC.memory = self.selectedMemory
            self.selectedMemory = nil
        }
        else if segue.identifier == "createMemory" {
            
        }
    }
    
    //MARK: - Reloading
    func reload() {
        //Fetch the memories.
        self.retrievedMemories = MKCoreData.shared.fetchAllMemories()

//        for memory in retrievedMemories {
//            memory.addToUserInfoQueue(withSession: wcSession, withTransferSetting: .update)
//        }
        
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    //MARK: - Notification Center functions.
    @objc func didRecieveDeveloperToken() {
    }
    
    @objc func didRecieveMusicUserToken() {
//            //Create a new memory.
//            let memory = MKCoreData.shared.createNewMKMemory()
//            memory.title = "WWDC 17"
//            memory.startDate = Date()
//
//            let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 0, maxAddsPerAlbum: 200)
//            memory.update(withSettings: updateSettings, andCompletion: { (complete) in
//                if complete {
//                    memory.save()
//                    self.reload()
//                }
//            })
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
    
    @objc func pop() {
        self.navigationController?.popToRootViewController(animated: true)
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


//MARK: - PeekPopPreviewingDelegate
extension HomeViewController: UIViewControllerPreviewingDelegate {
    
    //Peek function.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView?.indexPathForItem(at: location) {
            if let cell = self.collectionView?.cellForItem(at: indexPath) {
                if let cell = cell as? MemoryCell {
                    //Setup the previewing context
                    previewingContext.sourceRect = cell.frame
                    
                    //Set the popped memory.
                    self.poppedMemory = self.retrievedMemories[indexPath.item - 1]
                    self.poppedIndexPath = indexPath
                    
                    //Create the view controller
                    let vc = MemorySettingsViewController(nibName: "MemorySettingsViewController", bundle: nil)
                    vc.titleStr = self.poppedMemory?.title ?? ""
                    vc.dateStr = String(describing: self.poppedMemory?.startDate)
                    
                    //Set the content size of the view controller to preview.
                    vc.preferredContentSize = CGSize(width: self.view.frame.width - 40, height: 100)
                    return vc
                }
                return nil
            }
            return nil
        }
        return nil
    }

    
    //Pop function.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.blurUnderlay = UIVisualEffectView(effect: Settings.shared.blurEffect)
        self.blurUnderlay?.frame = self.view.frame
        UIApplication.shared.keyWindow?.addSubview(self.blurUnderlay!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissFromTap))
        self.blurUnderlay?.contentView.addGestureRecognizer(tapGesture)
        
        self.poppedViewController = viewControllerToCommit as? MemorySettingsViewController
        self.poppedViewController?.view.frame.size = CGSize(width: self.view.frame.width - 40, height: 103)
        self.poppedViewController?.view.center = CGPoint(x: self.view.frame.width / 2, y: self.view.frame.height / 2)
        self.poppedViewController?.background.layer.cornerRadius = 25
        self.poppedViewController?.background.clipsToBounds = true
        UIApplication.shared.keyWindow?.addSubview(self.poppedViewController!.view)
        
        self.addActionView()
    }
    
    func addActionView() {
        self.actionView = MemorySettingsActionView.fromNib()
        self.actionView?.frame = CGRect(x: 0, y: self.view.frame.height - 16 - MemorySettingsActionView.requiredHeight, width: (self.poppedViewController?.view.frame.width)!, height: MemorySettingsActionView.requiredHeight)
        self.actionView?.center.x = self.view.frame.width / 2
        
        let center = self.actionView!.center
        
        //Setting action view callbacks.
        //Edit callback
        self.actionView?.editCallback = {
            //Dismiss the popover and open the edit screen.
            self.dismissPoppedViewController()
        }
        
        //Delete callback
        self.actionView?.deleteCallback = {
            //Dismiss the popover, and delete the memory, reload the collection view.
            self.dismissPoppedViewController {
                
                //Send delete message to user's Watch.
                self.poppedMemory?.addToUserInfoQueue(withSession: wcSession, withTransferSetting: .delete)
                
                //Delete the memory locally.
                self.poppedMemory?.delete()
                self.retrievedMemories.remove(at: self.poppedIndexPath!.item - 1)
                
                //Update the UI
                self.collectionView?.performBatchUpdates({
                    self.collectionView?.deleteItems(at: [self.poppedIndexPath!])
                }, completion: { (complete) in
                    if complete {
                        self.reload()
                    }
                })
            }
        }
        
        //Cancel callback.
        self.actionView?.cancelCallback = {
            //Just dismiss the popover.
            self.dismissPoppedViewController()
        }
        
        UIApplication.shared.keyWindow?.addSubview(self.actionView!)
        self.actionView?.present(toPoint: center)
        
        if actionView != nil && poppedViewController != nil && poppedViewController!.view.frame.contains(actionView!.frame.origin) {
            poppedViewController!.view.frame.origin.y = actionView!.frame.origin.y - 103 - 16
        }
    }
    
    @objc func dismissFromTap() {
        self.dismissPoppedViewController()
    }
    
    func dismissPoppedViewController(withCompletion completion: (()->Void)? = nil) {
        self.actionView?.dismiss {
            self.actionView = nil
        }
        Haptics.shared.sendImpactHaptic(withStyle: .medium)
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.poppedViewController?.view.transform = CGAffineTransform(scaleX: 2, y: 2)
            self.poppedViewController?.view.alpha = 0
            self.blurUnderlay?.effect = nil
        }) { (completed) in
            if completed {
                self.blurUnderlay?.removeFromSuperview()
                self.poppedViewController?.view.removeFromSuperview()
                self.blurUnderlay = nil
                self.poppedViewController = nil
                
                DispatchQueue.main.async {
                    if let completion = completion {
                        completion()
                    }
                    self.poppedMemory = nil
                }
            }
        }
    }
}
