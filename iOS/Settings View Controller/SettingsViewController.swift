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

class SettingsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    //MARK: - Properties
    //Settings content.
    var settings = ["Visual" : [SettingsOption.darkMode], "Dynamic Memories" : [SettingsOption.enableDynamicMemories, SettingsOption.dynamicMemoryTimeLength, SettingsOption.autoAddPlaylists], "App Info" : [SettingsOption.versionInfo, SettingsOption.copyrightInfo]]
    var keys = ["Visual", "Dynamic Memories", "App Info"]
    var switches = [String: UISwitch]()
    var timePeriodField: UITextField!
    var tableViewBackground: UIVisualEffectView!
    var timePeriodPickerView: UIPickerView!

    //MARK: - UIViewController Overrides
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
        
        if Settings.shared.enableDynamicMemories == false {
            self.settings["Dynamic Memories"]?.remove(at: 1)
            self.settings["Dynamic Memories"]?.remove(at: 1)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.reloadData()
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
        return settings[self.keys[section]]!.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]
        if thisSetting.subtitle != nil {
            return 85
        }
        return 45
    }
    
    //MARK: - Cell setup.
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
            self.setup(switchCell: cell, withSetting: thisSetting)
        }
        else if thisSetting.interface == .uiTextField {
            self.setup(textFieldCell: cell, withSetting: thisSetting)
        }
        else if thisSetting.interface == .uiPickerView {
            //Picker view
            let interface = NumberPickerView(frame: CGRect(x: 0, y: 0, width: 60, height: 100))
            cell.clipsToBounds = true
            cell.accessoryView = interface
        }
        
        return cell
    }
    
    ///Sets up the cell with a switch as the accessory view.
    func setup(switchCell cell: UITableViewCell, withSetting setting: SettingsOption) {
        //UISwitch
        let interface = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
        interface.onTintColor = .themeColor
        interface.addTarget(self, action: #selector(self.switchValueChanged(_:)), for: .valueChanged)
        cell.accessoryView = interface
        
        //Set on value.
        if setting == .darkMode {
            interface.isOn = Settings.shared.darkMode
        }
        if setting == .enableDynamicMemories {
            interface.isOn = Settings.shared.enableDynamicMemories
        }
        if setting == .autoAddPlaylists {
            interface.isOn = Settings.shared.addDynamicMemoriesToLibrary
        }
        
        //Add to the switches array.
        self.switches[setting.displayTitle] = interface
    }
    
    ///Sets up the cell with a text field as the accessory view.
    func setup(textFieldCell cell: UITableViewCell, withSetting setting: SettingsOption) {
        //Text field
        let interface = UITextField(frame: CGRect(x: 0, y: 0, width: 70, height: 35))
        interface.placeholder = "Time Period"
        interface.keyboardType = .alphabet
        interface.textColor = Settings.shared.textColor
        interface.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        interface.textAlignment = .right
        interface.tintColor = .clear
        interface.delegate = self
        cell.accessoryView = interface
        
        //Setup the picker view.
        self.timePeriodPickerView = UIPickerView(frame: .zero)
        self.timePeriodPickerView.delegate = self
        self.timePeriodPickerView.dataSource = self
        interface.inputView = self.timePeriodPickerView
        
        for i in 0..<self.rowTitles.count {
            if rowTitles[i] == Settings.shared.dynamicMemoriesUpdatePeriod {
                self.timePeriodPickerView.selectRow(i, inComponent: 0, animated: false)
            }
        }
        
        self.timePeriodField = interface
        
        //Set the selection style.
        cell.selectionStyle = .default
        
        cell.selectedBackgroundView = nil
        
        if setting == .dynamicMemoryTimeLength {
            interface.text = Settings.shared.dynamicMemoriesUpdatePeriod.rawValue
        }
    }
   
    //MARK: - Table View Header
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
    
    //MARK: - Cell highlighting and selection
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            self.highlight(cell: tableView.cellForRow(at: indexPath)!, true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            self.highlight(cell: tableView.cellForRow(at: indexPath)!, false)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 1 {
            self.timePeriodField.becomeFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            self.highlight(cell: tableView.cellForRow(at: indexPath)!, false)
        }
    }
    
    //MARK: - Cell highlighting.
    func highlight(cell: UITableViewCell, _ highlight: Bool) {
        if let textField = cell.accessoryView as? UITextField {
            textField.textColor = highlight ? (Settings.shared.darkMode ? .black : .white) : Settings.shared.textColor
        }
        cell.textLabel?.textColor = highlight ? (Settings.shared.darkMode ? .black : .white) : Settings.shared.textColor
        cell.detailTextLabel?.textColor = highlight ? (Settings.shared.darkMode ? .black : .white) : Settings.shared.textColor
    }
    
    //MARK: - UIPickerView
    let rowTitles: [Settings.DynamicMemoriesUpdatePeriod] = [.Weekly, .Biweekly, .Monthly, .Yearly]
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return rowTitles.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return rowTitles[row].rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        Settings.shared.dynamicMemoriesUpdatePeriod = rowTitles[row]
        self.timePeriodField.text = rowTitles[row].rawValue
    }

    
    //MARK: - Switch value change.
    @objc func switchValueChanged(_ sender: UISwitch) {
        //Determine the setting for the switch.
        if sender == switches[SettingsOption.darkMode.displayTitle] {
            //Dark mode
            Settings.shared.darkMode = sender.isOn
        }
        else if sender == switches[SettingsOption.enableDynamicMemories.displayTitle] {
            if MKAuth.canBecomeAppleMusicSubscriber && !MKAuth.isAppleMusicSubscriber {
                sender.isOn = false
                self.showSubscribeVC()
                return
            }
            //Enable / disable dynamic memories.
            Settings.shared.enableDynamicMemories = sender.isOn
            
            self.tableView.estimatedRowHeight = 0
            self.tableView.estimatedSectionFooterHeight = 0
            self.tableView.estimatedSectionHeaderHeight = 0
            
            //Remove or add cells as necessary.
            if sender.isOn {
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.tableView.beginUpdates()
                    //Add cells.
                    self.settings["Dynamic Memories"]?.append(SettingsOption.dynamicMemoryTimeLength)
                    self.settings["Dynamic Memories"]?.append(SettingsOption.autoAddPlaylists)
                    
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)], with: .fade)
                    self.tableView.endUpdates()
                })
                self.tableView.setEditing(false, animated: true)
                CATransaction.commit()
            }
            else {
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.tableView.beginUpdates()
                    //Remove cells.
                    self.settings["Dynamic Memories"]?.remove(at: 1)
                    self.settings["Dynamic Memories"]?.remove(at: 1)
                    
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)], with: .fade)
                    self.tableView.endUpdates()
                })
                self.tableView.setEditing(false, animated: true)
                CATransaction.commit()
            }
            
        }
        else if sender == switches[SettingsOption.autoAddPlaylists.displayTitle] {
            Settings.shared.addDynamicMemoriesToLibrary = sender.isOn
        }
    }
    
    //MARK: - Show subscribe view controller.
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
    
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
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

extension SettingsViewController: SKCloudServiceSetupViewControllerDelegate {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        cloudServiceSetupViewController.dismiss(animated: true, completion: nil)
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
            return "Copyright © 2018 Collin DeWaters. All rights reserved."
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
