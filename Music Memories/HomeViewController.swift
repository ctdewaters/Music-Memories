//
//  HomeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import PeekPop

var homeVC: HomeViewController!

class HomeViewController: UICollectionViewController {
    
    //MARK: - Properties
    var retrievedMemories = [MKMemory]()
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    var peekPop: PeekPop!
    var blurUnderlay: UIVisualEffectView?
    var poppedViewController: MemorySettingsViewController?
    var actionView: MemorySettingsActionView?
    var poppedMemory: MKMemory?
    
    var selectedMemory: MKMemory?
    
    //MARK: - View loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        homeVC = self

        self.peekPop = PeekPop(viewController: self)
        self.peekPop.registerForPreviewingWithDelegate(self, sourceView: self.collectionView!)
        
        // Register cell classes
        let addMemoryNib = UINib(nibName: "AddMemoryCell", bundle: nil)
        self.collectionView!.register(addMemoryNib, forCellWithReuseIdentifier: "addMemory")
        let memoryNib = UINib(nibName: "MemoryCell", bundle: nil)
        self.collectionView!.register(memoryNib, forCellWithReuseIdentifier: "memory")
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(self.pop))


        let deviceName = UIDevice.current.name
        if var userFirstName = deviceName.components(separatedBy: " ").first {
            userFirstName = userFirstName.replacingOccurrences(of: "s", with: "")
            userFirstName = userFirstName.replacingOccurrences(of: "\'", with: "")
            if userFirstName.last == "’" {
                userFirstName.removeLast()
            }
            navigationItem.title = "Hello, \(userFirstName.replacingOccurrences(of: "'s", with: ""))!"
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
            
            self.selectedMemory = self.retrievedMemories[indexPath.item - 1]
            self.performSegue(withIdentifier: "openMemory", sender: self)
        }
    }
    
    //MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
    
        if segue.identifier == "openMemory" {
            //Setup the memory view controller.
            
            let destinationVC = segue.destination as! MemoryViewController
            destinationVC.memory = self.selectedMemory
            self.selectedMemory = nil
        }
    }
    
    //MARK: - Reloading
    func reload() {
        self.retrievedMemories = MKCoreData.shared.fetchAllMemories()
        print(self.retrievedMemories.count)
        DispatchQueue.main.async {
            self.collectionView?.reloadData()
        }
    }
    
    //MARK: - Notification Center functions.
    @objc func didRecieveDeveloperToken() {
    }
    
    @objc func didRecieveMusicUserToken() {
                
        self.reload()
        if self.retrievedMemories.count == 0 {
            //Create a new memory.
            let memory = MKCoreData.shared.createNewMKMemory()
            memory.title = "My First Memory"
            memory.startDate = Date()
            
            let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: true, playCount: 0, maxAddsPerAlbum: 200)
            memory.update(withSettings: updateSettings, andCompletion: { (complete) in
                if complete {
                    memory.save()
                    self.reload()
                }
            })
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
    
    @objc func pop() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
}


//MARK: - PeekPopPreviewingDelegate
extension HomeViewController: PeekPopPreviewingDelegate {
    func previewingContext(_ previewingContext: PreviewingContext, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = self.collectionView?.indexPathForItem(at: location) {
            if let cell = self.collectionView?.cellForItem(at: indexPath) {
                if let cell = cell as? MemoryCell {
                    //Setup the previewing context
                    previewingContext.sourceRect = cell.frame
                    
                    //Set the popped memory.
                    self.poppedMemory = self.retrievedMemories[indexPath.item - 1]
        
                    //Create the view controller
                    let vc = MemorySettingsViewController(nibName: "MemorySettingsViewController", bundle: nil)
                    vc.titleStr = self.poppedMemory?.title ?? ""
                    vc.dateStr = String(describing: self.poppedMemory?.startDate) ?? ""
                    

                    vc.preferredContentSize = CGSize(width: self.view.frame.width - 40, height: 100)
                    return vc
                }
                return nil
            }
            return nil
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: PreviewingContext, commitViewController viewControllerToCommit: UIViewController) {
        self.blurUnderlay = UIVisualEffectView(effect: UIBlurEffect(style: .light))
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
                self.poppedMemory?.delete()
                self.reload()
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
