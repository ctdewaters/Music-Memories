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

class SettingsLegacyViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    //MARK: - Properties
    //Settings content.
    var settings = Settings.all
    var keys = Array(Settings.all.keys)
    var switches = [String: UISwitch]()
    var timePeriodField: UITextField!
    var timePeriodPickerView: UIPickerView!

    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //Navigation and tab bar setup.
        self.setupNavigationBar()

        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        
        //Add blur
        self.tableView.separatorStyle = .singleLine
        
        ///Block separators beneath used cells with a clear view.
        let clearView = UIView()
        clearView.backgroundColor = .clear
        self.tableView.tableFooterView = clearView
        
        if Settings.shared.dynamicMemoriesEnabled == false {
            self.settings["Dynamic Memories"]?.remove(at: 1)
            self.settings["Dynamic Memories"]?.remove(at: 1)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hideHairline()

        self.tableView.backgroundColor = .background
        self.settingsDidUpdate()
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
        if indexPath.section == 2 {
            return 65
        }
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]
        let titleHeight = thisSetting.displayTitle.height(withConstrainedWidth: self.view.frame.width * 0.65, font: UIFont.preferredFont(forTextStyle: .headline))
        let subtitleHeight = thisSetting.subtitle?.height(withConstrainedWidth: self.view.frame.width * 0.65, font: UIFont.preferredFont(forTextStyle: .subheadline)) ?? 0
        return titleHeight + subtitleHeight + 20
    }
    
    //MARK: - Cell setup.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisSetting = settings[self.keys[indexPath.section]]![indexPath.row]

        //Create the cell.
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = thisSetting.displayTitle
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        cell.textLabel?.textColor = Settings.shared.textColor
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        //Set selection style
        cell.selectionStyle = .none
        
        if indexPath.section == 2 {
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
            cell.textLabel?.textColor = .secondaryText
        }
        
        if let subtitle = thisSetting.subtitle {
            cell.detailTextLabel?.text = subtitle
            cell.detailTextLabel?.textColor = .secondaryText
            cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.lineBreakMode = .byWordWrapping
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
    func setup(switchCell cell: UITableViewCell, withSetting setting: Settings.Option) {
        //UISwitch
        let interface = UISwitch(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
        interface.onTintColor = .theme
        interface.addTarget(self, action: #selector(self.switchValueChanged(_:)), for: .valueChanged)
        cell.accessoryView = interface
        
        //Set on value.
        if setting == .darkMode {
            interface.isOn = Settings.shared.darkMode
        }
        if setting == .enableDynamicMemories {
            interface.isOn = Settings.shared.dynamicMemoriesEnabled
        }
        if setting == .autoAddPlaylists {
            interface.isOn = Settings.shared.addDynamicMemoriesToLibrary
        }
        
        //Add to the switches array.
        self.switches[setting.displayTitle] = interface
    }
    
    ///Sets up the cell with a text field as the accessory view.
    func setup(textFieldCell cell: UITableViewCell, withSetting setting: Settings.Option) {
        //Text field
        let interface = UITextField(frame: CGRect(x: 0, y: 0, width: 70, height: 35))
        interface.placeholder = "Time Period"
        interface.keyboardType = .alphabet
        interface.textColor = Settings.shared.textColor
        interface.font = UIFont.preferredFont(forTextStyle: .footnote)
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
        label.text = "    \(self.keys[section].uppercased())"
        label.backgroundColor = .secondaryBackground
        label.textColor = .text
        return label
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.keys[section].uppercased().height(withConstrainedWidth: self.view.frame.width, font: UIFont.preferredFont(forTextStyle: .subheadline)) + 15
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
        if sender == switches[Settings.Option.darkMode.displayTitle] {
            //Dark mode
            Settings.shared.darkMode = sender.isOn
        }
        else if sender == switches[Settings.Option.enableDynamicMemories.displayTitle] {
            if MKAuth.canBecomeAppleMusicSubscriber && !MKAuth.isAppleMusicSubscriber {
                sender.isOn = false
                self.showSubscribeVC()
                return
            }
            //Enable / disable dynamic memories.
            Settings.shared.dynamicMemoriesEnabled = sender.isOn
            
            self.tableView.estimatedRowHeight = 0
            self.tableView.estimatedSectionFooterHeight = 0
            self.tableView.estimatedSectionHeaderHeight = 0
            
            //Remove or add cells as necessary.
            if sender.isOn {
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.tableView.beginUpdates()
                    //Add cells.
                    self.settings["Dynamic Memories"]?.append(Settings.Option.dynamicMemoryTimeLength)
                    self.settings["Dynamic Memories"]?.append(Settings.Option.autoAddPlaylists)
                    
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
        else if sender == switches[Settings.Option.autoAddPlaylists.displayTitle] {
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
    
    
    //MARK: Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.navigationForeground]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        
        self.tableView.separatorColor = .secondaryText
        
        UIView.animate(withDuration: 0.1) {
            self.tableView.backgroundColor = .background
            self.tableView.reloadData()
        }
    }
}

extension SettingsLegacyViewController: SKCloudServiceSetupViewControllerDelegate {
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        cloudServiceSetupViewController.dismiss(animated: true, completion: nil)
    }
}