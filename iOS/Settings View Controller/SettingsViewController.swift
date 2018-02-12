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
    let settings = ["Visual" : [SettingsOption.darkMode], "Dynamic Memories" : [SettingsOption.enableDynamicMemories, SettingsOption.dynamicMemoryTimeLength, SettingsOption.autoAddPlaylists], "App Info" : [SettingsOption.versionInfo, SettingsOption.copyrightInfo]]
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
        
        let clearView = UIView()
        clearView.backgroundColor = .clear
        self.tableView.tableFooterView = clearView
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
            return 85
        }
        return 45
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = thisSetting.displayTitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        cell.textLabel?.textColor = Settings.shared.textColor
        cell.textLabel?.numberOfLines = 0
        
        //Set selection style
        cell.selectionStyle = .none
        
        if indexPath.section == 2 {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            cell.textLabel?.textColor = Settings.shared.accessoryTextColor
        }
        
        if let subtitle = thisSetting.subtitle {
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.textColor = Settings.shared.accessoryTextColor
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            cell.detailTextLabel?.numberOfLines = 0
        }
        else {
            cell.detailTextLabel?.text = ""
        }
        
        cell.backgroundColor = .clear
        
        //Determine interface.
        if thisSetting.interface == .uiSwitch {
            //UISwitch
            let interface = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
            interface.onTintColor = .themeColor
            interface.addTarget(self, action: #selector(self.switchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = interface
            
            //Set on value.
            if thisSetting == .darkMode {
                interface.isOn = Settings.shared.darkMode
            }
            if thisSetting == .enableDynamicMemories {
                interface.isOn = Settings.shared.enableDynamicMemories
            }
            if thisSetting == .autoAddPlaylists {
                interface.isOn = Settings.shared.addDynamicMemoriesToLibrary
            }
            
            //Add to the switches array.
            self.switches[thisSetting.displayTitle] = interface
        }
        else if thisSetting.interface == .uiTextField {
            //Text field
            let interface = UITextField(frame: CGRect(x: 0, y: 0, width: 60, height: 50))
            interface.placeholder = "Time Period"
            interface.keyboardType = .alphabet
            interface.textColor = Settings.shared.textColor
            interface.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            interface.textAlignment = .right
            cell.accessoryView = interface
            cell.selectionStyle = .default
            
            if thisSetting == .dynamicMemoryTimeLength {
                interface.text = Settings.shared.dynamicMemoriesUpdatePeriod.rawValue
            }
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Deselect the row.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Switch value change.
    @objc func switchValueChanged(_ sender: UISwitch) {
        //Determine the setting for the switch.
        if sender == switches[SettingsOption.darkMode.displayTitle] {
            //Dark mode
            Settings.shared.darkMode = sender.isOn
        }
        else if sender == switches[SettingsOption.enableDynamicMemories.displayTitle] {
            //Enable / disable dynamic memories.
            Settings.shared.enableDynamicMemories = sender.isOn
        }
        else if sender == switches[SettingsOption.autoAddPlaylists.displayTitle] {
            Settings.shared.addDynamicMemoriesToLibrary = sender.isOn
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
    case enableDynamicMemories, dynamicMemoryTimeLength, autoAddPlaylists, darkMode, versionInfo, copyrightInfo
    
    var isMemorySetting: Bool {
        if self == .enableDynamicMemories || self == .dynamicMemoryTimeLength || self == .autoAddPlaylists {
            return true
        }
        return false
    }
    
    var isVisualSetting: Bool {
        if self == .darkMode {
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
        if self == .dynamicMemoryTimeLength {
            return .uiTextField
        }
        return .uiSwitch
    }
    
    var displayTitle: String {
        switch self {
        case .enableDynamicMemories :
            return "Enable Dynamic Memories"
        case .dynamicMemoryTimeLength :
            return "Dynamic Memory Time Period"
        case .autoAddPlaylists :
            return "Add Memories to My Library"
        case .darkMode :
            return "Dark Mode"
        case .versionInfo :
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                return "Version \(version)"
            }
            return "Version -.-.-"
        case .copyrightInfo :
            return "Copyright © 2018 Near Future Marketing. All rights reserved."
        }
    }
    
    var subtitle: String? {
        switch self {
        case .enableDynamicMemories :
            return "When enabled, Music Memories will create memories using your listening activity automatically."
        case .dynamicMemoryTimeLength :
            return "Specify the length of time for dynamic memories to be created."
        case .autoAddPlaylists :
            return "Automatically add dynamic memories to your music library as playlists."
        case .darkMode :
            return "Enable a darker UI."
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
