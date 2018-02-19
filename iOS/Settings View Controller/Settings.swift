//
//  Settings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

///Handles setting changes for the whole application.
class Settings {
    
    ///The shared instance.
    static let shared = Settings()
    
    //User defaults reference.
    let userDefaults = UserDefaults.standard
    
    ///Notification name for settings updated.
    static let didUpdateNotification = Notification.Name("settingsDidUpdate")
    
    fileprivate enum SettingsKey: String {
        case darkMode, enableDynamicMemories, dynamicMemoryUpdatePeriod, addDynamicMemoriesToLibrary
    }
    
    //MARK: - Dark Mode
    var darkMode: Bool {
        set {
            userDefaults.set(newValue, forKey: SettingsKey.darkMode.rawValue)
            NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
        }
        get {
            return userDefaults.bool(forKey: SettingsKey.darkMode.rawValue)
        }
    }
    
    //The blur effect to use (responds to dark mode).
    var blurEffect: UIBlurEffect? {
        return darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }
    
    var accessoryTextColor: UIColor {
        return darkMode ? .lightGray : .darkGray
    }
    
    var textColor: UIColor {
        return darkMode ? .white : .black
    }

    var barStyle: UIBarStyle {
        return darkMode ? .black : .default
    }
    
    var statusBarStyle: UIStatusBarStyle {
        return darkMode ? .lightContent : .default
    }
    
    var keyboardAppearance: UIKeyboardAppearance {
        return darkMode ? .dark : .default
    }
    
    //MARK: - Enable Dynamic Memories
    var enableDynamicMemories: Bool {
        set {
            userDefaults.set(newValue, forKey: SettingsKey.enableDynamicMemories.rawValue)
            NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
        }
        get {
            if let value = userDefaults.value(forKey: SettingsKey.enableDynamicMemories.rawValue) as? Bool {
                return value
            }
            
            //Set default value to true.
            self.enableDynamicMemories = true
            return true
        }
    }
    
    //MARK: - Dynamic Memories Update Period.
    enum DynamicMemoriesUpdatePeriod: String {
        case Weekly, Biweekly, Monthly, Yearly
        
        var days: Int {
            if self == .Weekly {
                return 7
            }
            if self == .Biweekly {
                return 14
            }
            if self == .Monthly {
                return 30
            }
            if self == .Yearly {
                return 365
            }
            return 0
        }
    }
    
    ///The dynamic memories update period (defaults to monthly).
    var dynamicMemoriesUpdatePeriod: DynamicMemoriesUpdatePeriod {
        set {
            if let currentDynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                currentDynamicMemory.endDate = Date()
                currentDynamicMemory.save()
                
                homeVC?.handleDynamicMemory()
            }
            
            userDefaults.set(newValue.rawValue, forKey: SettingsKey.dynamicMemoryUpdatePeriod.rawValue)
        }
        get {
            if let rawValue = userDefaults.value(forKey: SettingsKey.dynamicMemoryUpdatePeriod.rawValue) as? String {
                if let period = DynamicMemoriesUpdatePeriod(rawValue: rawValue) {
                    return period
                }
            }
            //Set to monthly.
            self.dynamicMemoriesUpdatePeriod = .Monthly
            
            //Return default as monthly.
            return .Monthly
        }
    }
    
    //MARK: - Add Dynamic Memories to library.
    var addDynamicMemoriesToLibrary: Bool {
        set {
            userDefaults.set(newValue, forKey: SettingsKey.addDynamicMemoriesToLibrary.rawValue)
        }
        get {
            if let value = userDefaults.value(forKey: SettingsKey.addDynamicMemoriesToLibrary.rawValue) as? Bool {
                return value
            }
            
            //Set default value to true.
            self.addDynamicMemoriesToLibrary = true
            return true
        }
    }

}
