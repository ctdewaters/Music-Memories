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
    let settings = ["Memory Settings" : [SettingsOption.fetchRecentlyPlayed, SettingsOption.fetchHeavyRotation, SettingsOption.fetchPlayCountTarget, SettingsOption.autoAddPlaylists], "Visual Settings" : [SettingsOption.darkMode, SettingsOption.blur], "Personal Settings" : [SettingsOption.name], "App Info" : [SettingsOption.versionInfo, SettingsOption.copyrightInfo]]
    let keys = ["Memory Settings", "Visual Settings", "Personal Settings", "App Info"]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        //Add blur
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blur.frame = self.view.frame
        self.tableView.backgroundView = blur
        self.tableView.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings[self.keys[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]

        let cell = UITableViewCell()
        cell.textLabel?.text = thisSetting.displayTitle
        cell.backgroundColor = .clear
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0)
        label.text = "   \(self.keys[section].uppercased())"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }
    
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        //self.performSegue(withIdentifier: "settingsToHome", sender: self)
        self.dismiss(animated: true, completion: nil)
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
}

enum SettingsInterface {
    case uiSwitch, uiPickerView, uiTextField, none
}
