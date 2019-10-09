//
//  SettingsTableViewCells.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/9/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

/// `SettingsCell`: A `UITableViewCell` subclass for the cells displayed in the settings table view.
class SettingsCell: UITableViewCell {
    
    ///An image view which displays the associated icon.
    @IBOutlet weak var icon: UIImageView?
    
    ///A background view for the icon image view.
    @IBOutlet weak var iconBackgroundView: UIView?
    
    ///A label to display the title of the associated settings option.
    @IBOutlet weak var titleLabel: UILabel!
    
    ///A label to display the subtitle/description of the associated settings option.
    @IBOutlet weak var subtitleLabel: UILabel!
    
    ///The settings option displayed in this cell.
    var settingsOption: Settings.Option?
    
    /// Sets up this cell's UI with a given setting option.
    /// - Parameter setting: The setting option to create setup this cell with.
    func setup(withSettingsOption setting: Settings.Option) {
        self.settingsOption = setting
        
        if setting == .enableDynamicMemories {
            //Check if user is an Apple Music subscriber, and disable if not.
            if !MKAuth.isAppleMusicSubscriber {
                self.isUserInteractionEnabled = false
                self.contentView.alpha = 0.5
                self.titleLabel.text = setting.displayTitle
                self.subtitleLabel.text = "This setting requires an Apple Music subscription."
                if #available(iOS 13.0, *) {
                    self.icon?.image = UIImage(systemName: setting.displayIconSystemName ?? "")
                }
                self.iconBackgroundView?.backgroundColor = setting.displayIconBackgroundColor
                return
            }
        }
        
        //Setup UI.
        self.titleLabel.text = setting.displayTitle
        self.subtitleLabel.text = setting.subtitle
        if #available(iOS 13.0, *) {
            self.icon?.image = UIImage(systemName: setting.displayIconSystemName ?? "")
        }
        self.iconBackgroundView?.backgroundColor = setting.displayIconBackgroundColor
    }
}

/// `SettingsSwitchCell`:  A `SettingsCell` that displays a switch interface.
class SettingsSwitchCell: SettingsCell {
    ///The switch which is displayed in the accessory view.
    @IBOutlet weak var uiSwitch: UISwitch!
    
    ///An optional callback to run when the switch's value has changed.
    var callback: (()->Void)?
        
    @IBAction func switchValueChanged(_ sender: Any) {
        guard let settingsOption = self.settingsOption else {
            return
        }
        
        switch settingsOption {
        case .darkMode :
            Settings.shared.darkMode = self.uiSwitch.isOn
        case .enableDynamicMemories :
            Settings.shared.dynamicMemoriesEnabled = self.uiSwitch.isOn
        case .addDynamicMemoriesToLibrary :
            Settings.shared.addDynamicMemoriesToLibrary = self.uiSwitch.isOn
        default :
            break
        }
        
        //Run the optional callback block.
        self.callback?()
        
        //Update the server settings with this change.
        let serverSettings = Settings.shared.serverSettings
        guard let dynamicMemories = serverSettings.dynamicMemories, let duration = serverSettings.duration, let addToLibrary = serverSettings.addToLibrary else { return }
        
        MKCloudManager.updateUserSettings(dynamicMemories: dynamicMemories, duration: duration, addToLibrary: addToLibrary)
    }
    
    override func setup(withSettingsOption setting: Settings.Option) {
        super.setup(withSettingsOption: setting)
        
        //Set switch value.
        switch setting {
        case .darkMode :
            self.uiSwitch.isOn = Settings.shared.darkMode
        case .enableDynamicMemories :
            self.uiSwitch.isOn = Settings.shared.dynamicMemoriesEnabled
        case .addDynamicMemoriesToLibrary :
            self.uiSwitch.isOn = Settings.shared.addDynamicMemoriesToLibrary
        default :
            break
        }
    }
}

/// `SettingsSubtitleCell`:  A `SettingsCell` that displays a only a title and subtitle label.
class SettingsSubtitleCell: SettingsCell {}

/// `SettingsLabelCell`:  A `SettingsCell` that acts as a navigation cell, displaying a nav arrow and label.
class SettingsLabelCell: SettingsCell {
    ///The accessory label.
    @IBOutlet weak var accessoryLabel: UILabel?
        
    override func setup(withSettingsOption setting: Settings.Option) {
        super.setup(withSettingsOption: setting)
        
        //Setup accessory label.
        if setting == Settings.Option.dynamicMemoryDuration {
            self.accessoryLabel?.text = Settings.shared.dynamicMemoriesUpdatePeriod.rawValue
        }
    }
}

class SettingsLogoCell: UITableViewCell {}
