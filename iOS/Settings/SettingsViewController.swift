//
//  SettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/18/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//
import UIKit
import MemoriesKit
import IQKeyboardManagerSwift
import StoreKit
import SwiftVideoBackground

class SettingsViewController: UITableViewController, UITextFieldDelegate {
    
    //MARK:  - Properties
    //Settings content.
    var settings = Settings.all
    var keys = Settings.allKeys

    //MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Navigation and tab bar setup.
        self.setupNavigationBar()
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: MKCloudManager.serverSettingsDidRefreshNotification, object: nil)
                                
        ///Block separators beneath used cells with a clear view.
        let clearView = UIView()
        clearView.backgroundColor = .clear
        self.tableView.tableFooterView = clearView
        
        if Settings.shared.dynamicMemoriesEnabled == false {
            self.settings["Dynamic Memories"]?.remove(at: 1)
            self.settings["Dynamic Memories"]?.remove(at: 1)
        }
        
        self.tableView.contentInset.bottom = CDMiniPlayer.State.closed.size.height + 16.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hideHairline()

        self.settingsDidUpdate()
        
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Update the mini player's padding.
        let padding = self.tabBarController?.tabBar.frame.height ?? 0
        self.updateMiniPlayerWithPadding(padding: padding)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Settings.didUpdateNotification, object: nil)
    }

    //MARK: - UITableView functions
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings[self.keys[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let setting = settings[self.keys[indexPath.section]]![indexPath.row]
        if setting == .logo {
            return 250.0
        }
        
        //Setup height of the cell by calculating the necessary heights of the cell's labels.
        let constrainedWidth: CGFloat = self.view.readableContentGuide.layoutFrame.width - 147.0
        let titleHeight = setting.displayTitle.height(withConstrainedWidth: constrainedWidth, font: UIFont(name: "SFProRounded-Semibold", size: 18) ?? UIFont.systemFont(ofSize: 18))
        let subtitleHeight = setting.subtitle?.height(withConstrainedWidth: constrainedWidth, font: UIFont(name: "SFProRounded-Regular", size: 11) ?? UIFont.systemFont(ofSize: 11)) ?? 0
        
        var height = titleHeight + subtitleHeight + 25
        
        //Minimize height at 60px.
        height = height < 60 ? 60 : height
        return height
    }
    
    //MARK: - Cell setup.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let setting = settings[self.keys[indexPath.section]]![indexPath.row]
        
        //Create a table view cell with the setting based on its interface.
        switch setting.interface {
        case .uiSwitch :
            guard let switchCell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as? SettingsSwitchCell else {
                return UITableViewCell()
            }
            
            //If the setting is for enabling dynamic memories, set the callback.
            if setting == .enableDynamicMemories {
                switchCell.callback = self.dynamicMemoriesSettingChanged
            }
            
            switchCell.setup(withSettingsOption: setting)
            return switchCell
            
        case .uiTextField :
            guard let labelCell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as? SettingsLabelCell else {
                return UITableViewCell()
            }
            
            labelCell.setup(withSettingsOption: setting)
            return labelCell

        case .none :
            if setting == .logo {
                guard let logoCell = tableView.dequeueReusableCell(withIdentifier: "logoCell", for: indexPath) as? SettingsLogoCell else {
                    return UITableViewCell()
                }
                return logoCell
            }
            guard let subtitleCell = tableView.dequeueReusableCell(withIdentifier: "subtitleCell", for: indexPath) as? SettingsSubtitleCell else {
                return UITableViewCell()
            }
            
            subtitleCell.setup(withSettingsOption: setting)
            return subtitleCell
        }
    }
           
    //MARK: - Table View Header
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.keys[section]
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.keys[section].uppercased().height(withConstrainedWidth: self.view.frame.width, font: UIFont.preferredFont(forTextStyle: .subheadline)) + 15
    }
            
    //MARK: - Apple Music Subscription VC
    func showSubscribeVC() {
        let setupViewController = SKCloudServiceSetupViewController()
        setupViewController.delegate = self
        
        let setupOptions: [SKCloudServiceSetupOptionsKey: Any] = [.action: SKCloudServiceSetupAction.subscribe, .messageIdentifier: SKCloudServiceSetupMessageIdentifier.connect]
        
        setupViewController.load(options: setupOptions) { (success, error) in
            if success {
                self.present(setupViewController, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: SettingsDidUpdate
    func dynamicMemoriesSettingChanged() {
        if Settings.shared.dynamicMemoriesEnabled {
            //Add the other DM settings to the local settings dictionary.
            self.settings["Dynamic Memories"]?.append(contentsOf: [.dynamicMemoryDuration, .addDynamicMemoriesToLibrary])
            
            self.tableView.beginUpdates()
            if #available(iOS 13.0, *) {
                self.tableView.insertRows(at: [IndexPath(item: 1, section: 0), IndexPath(item: 2, section: 0)], with: .top)
            }
            else {
                self.tableView.insertRows(at: [IndexPath(item: 1, section: 1), IndexPath(item: 2, section: 1)], with: .top)
            }
            self.tableView.endUpdates()
            
            return
        }
        //Remove the other DM settings from the location settings dictionary.
        self.settings["Dynamic Memories"]?.removeSubrange(1...2)
        
        self.tableView.beginUpdates()
        if #available(iOS 13.0, *) {
            self.tableView.deleteRows(at: [IndexPath(item: 1, section: 0), IndexPath(item: 2, section: 0)], with: .top)
        }
        else {
            self.tableView.deleteRows(at: [IndexPath(item: 1, section: 1), IndexPath(item: 2, section: 1)], with: .top)
        }
        self.tableView.endUpdates()
    }
    
    @objc func settingsDidUpdate() {
        self.tableView.reloadData()
    }
}

extension SettingsViewController: SKCloudServiceSetupViewControllerDelegate {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        cloudServiceSetupViewController.dismiss(animated: true, completion: nil)
    }
}
