//
//  SettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/18/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class SettingsViewController: UITableViewController {
    
    //Settings content.
    let settings = ["Visual" : [SettingsOption.darkMode], "Dynamic Memories" : [SettingsOption.fetchRecentlyPlayed, SettingsOption.fetchHeavyRotation, SettingsOption.autoAddPlaylists], "App Info" : [SettingsOption.versionInfo, SettingsOption.copyrightInfo]]
    let keys = ["Visual", "Dynamic Memories", "App Info"]
    
    var switches = [String: UISwitch]()
    
    var tableViewBackground: UIVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        navigationController?.navigationBar.tintColor = .themeColor
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        
        //Add blur
        self.tableViewBackground = UIVisualEffectView(effect: Settings.shared.blurEffect)
        self.tableViewBackground.frame = self.view.frame
        self.tableView.backgroundView = tableViewBackground
        self.tableView.backgroundColor = .clear
        self.tableView.separatorColor = Settings.shared.accessoryTextColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Settings.didUpdateNotification, object: nil)
    }

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[self.keys[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]
        if thisSetting.subtitle != nil {
            return 75
        }
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = thisSetting.displayTitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        cell.textLabel?.textColor = Settings.shared.textColor
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.section == 2 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
            cell.textLabel?.textColor = Settings.shared.accessoryTextColor
        }
        
        if let subtitle = thisSetting.subtitle {
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.textColor = Settings.shared.accessoryTextColor
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            cell.detailTextLabel?.numberOfLines = 0
        }
        else {
            cell.detailTextLabel?.text = ""
        }
        
        cell.backgroundColor = .clear
        
        //Determine interface.
        if thisSetting.interface == .uiSwitch {
            //UISwitch
            let interface = UISwitch(frame: CGRect(x: 0, y: 0, width: 80, height: 27))
            interface.onTintColor = .themeColor
            interface.addTarget(self, action: #selector(self.switchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = interface
            
            //Set status
            if thisSetting == .darkMode {
                interface.isOn = Settings.shared.darkMode
            }
            
            self.switches[thisSetting.displayTitle] = interface
        }
        else if thisSetting.interface == .uiTextField {
            //Text field
            let interface = UITextField(frame: CGRect(x: 0, y: 0, width: self.view.frame.width * 0.7, height: 50))
            interface.placeholder = "Enter name here..."
            interface.keyboardType = .alphabet
            cell.accessoryView = interface
        }
        else if thisSetting.interface == .uiPickerView {
            //Picker view
            let interface = NumberPickerView(frame: CGRect(x: 0, y: 0, width: 60, height: 100))
            cell.clipsToBounds = true
            cell.accessoryView = interface
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = Settings.shared.darkMode ? UIColor.darkGray : UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0)
        label.text = "   \(self.keys[section].uppercased())"
        label.textColor = Settings.shared.accessoryTextColor
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.keys[section].uppercased()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    @objc func switchValueChanged(_ sender: UISwitch) {
        //Determine the setting for the switch.
        if sender == switches[SettingsOption.darkMode.displayTitle] {
            //Dark mode
            Settings.shared.darkMode = sender.isOn
        }
    }
    
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        //self.performSegue(withIdentifier: "settingsToHome", sender: self)
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        
        self.tableView.separatorColor = Settings.shared.accessoryTextColor
        
        UIView.animate(withDuration: 0.25) {
            self.tableViewBackground.effect = Settings.shared.darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .extraLight)
            self.tableView.reloadData()
        }
    }
}

//MARK: - SettingsOption: represents a setting to display.
enum SettingsOption {
    case fetchRecentlyPlayed, fetchHeavyRotation, fetchPlayCountTarget, autoAddPlaylists, darkMode, blur, name, versionInfo, copyrightInfo
    
    var isMemorySetting: Bool {
        if self == .fetchRecentlyPlayed || self == .fetchHeavyRotation || self == .fetchPlayCountTarget || self == .autoAddPlaylists {
            return true
        }
        return false
    }
    
    var isVisualSetting: Bool {
        if self == .darkMode || self == .blur {
            return true
        }
        return false
    }
    
    var isPersonalInfoSetting: Bool {
        if self == .name {
            return true
        }
        return false
    }
    
    var isApplicationInfo: Bool {
        if self == .versionInfo || self == .copyrightInfo {
            return true
        }
        return false
    }
    
    var interface: SettingsInterface {
        if self.isApplicationInfo {
            return .none
        }
        if self.isPersonalInfoSetting {
            return .uiTextField
        }
        if self == .fetchPlayCountTarget {
            return .uiPickerView
        }
        return .uiSwitch
    }
    
    var displayTitle: String {
        switch self {
        case .fetchRecentlyPlayed :
            return "Retrieve from Recently Played"
        case .fetchHeavyRotation :
            return "Retrieve from Heavy Rotation"
        case .fetchPlayCountTarget :
            return "Max Songs Retrieved Per Album"
        case .autoAddPlaylists :
            return "Add Memories to My Library"
        case .darkMode :
            return "Dark Mode"
        case .blur :
            return "Blur Effect"
        case .name :
            return "My Name"
        case .versionInfo :
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                return "Version \(version)"
            }
            return "Version -.-.-"
        case .copyrightInfo :
            return "Copyright © 2017 Near Future Marketing. All rights reserved."
        }
    }
    
    var subtitle: String? {
        switch self {
        case .fetchRecentlyPlayed :
            return "Source music from your recently played songs into your dynamic memories."
        case .fetchHeavyRotation :
            return "Source music from your Heavy Rotation into your dynamic memories."
        case .fetchPlayCountTarget :
            return "Max Songs Retrieved Per Album"
        case .autoAddPlaylists :
            return "Automatically add dynamic memories to your music library as playlists."
        case .darkMode :
            return "Enable a darker UI."
        case .blur :
            return "Blur Effect"
        case .name :
            return "My Name"
        case .versionInfo :
            return nil
        case .copyrightInfo :
            return nil
        }
    }
}

enum SettingsInterface {
    case uiSwitch, uiPickerView, uiTextField, none
}
