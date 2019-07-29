//
//  Settings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import SwiftUI

///Handles setting changes for the whole application.
class Settings {
    
    ///The shared instance.
    static let shared = Settings()
    
    ///All of the settings to display.
    static var all: [String: [Settings.Option]] {
        if #available(iOS 13.0, *) {
            return ["Dynamic Memories" : [.enableDynamicMemories, .dynamicMemoryTimeLength, .autoAddPlaylists], "App Info" : [.versionInfo, .copyrightInfo]]
        }
        else {
            return ["Visual": [.darkMode], "Dynamic Memories" : [.enableDynamicMemories, .dynamicMemoryTimeLength, .autoAddPlaylists], "App Info" : [.versionInfo, .copyrightInfo]]

        }
    }
    
    ///All of the dynamic memory durations.
    static let allUpdatePeriods: [Settings.DynamicMemoriesUpdatePeriod] = [.Yearly, .Monthly, .Biweekly, .Weekly]
    
    //User defaults reference.
    let userDefaults = UserDefaults.standard
    
    ///Notification name for settings updated.
    static let didUpdateNotification = Notification.Name("settingsDidUpdate")
    
    ///`Settings.Key`:  keys for each available setting for storing in UserDefaults.
    fileprivate enum Key: String {
        case darkMode, enableDynamicMemories, dynamicMemoryUpdatePeriod, addDynamicMemoriesToLibrary
    }
    
    //MARK: - Initialization
    init() {
    }
    
    //MARK: - Dark Mode
    var darkMode: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.darkMode.rawValue)
            NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
        }
        get {
            return userDefaults.bool(forKey: Key.darkMode.rawValue)
        }
    }
    
    ///The blur effect to use (responds to dark mode).
    var blurEffect: UIBlurEffect? {
        if #available(iOS 13.0, *) {
            return UIBlurEffect(style: .systemMaterial)
        }
        return darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }
    
    ///The primary text color.
    var textColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        }
        return darkMode ? .white : .black
    }
    
    ///The secondary text color.
    var secondaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        }
        return darkMode ? UIColor(red: 243/255.0, green: 243/255.0, blue: 249/255.0, alpha: 1) : UIColor(red: 138/255.0, green: 138/255.0, blue: 142/255.0, alpha: 1)
    }
    
    ///The primary background color.
    var backgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        }
        return darkMode ? .black : .white
    }
    
    ///The secondary background color.
    var secondaryBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemBackground
        }
        return darkMode ? UIColor(red: 28/255.0, green: 28/255.0, blue: 30/255.0, alpha: 1) : UIColor(red: 242/255.0, green: 242/255.0, blue: 247/255.0, alpha: 1)
    }

    ///The default bar style.
    var barStyle: UIBarStyle {
        if #available(iOS 13.0, *) {
            return .default
        }
        return darkMode ? .black : .default
    }
    
    ///The default status bar style.
    var statusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .default
        }
        return darkMode ? .lightContent : .default
    }
    
    ///The default keyboard appearance.
    var keyboardAppearance: UIKeyboardAppearance {
        if #available(iOS 13.0, *) {
            return .default
        }
        return darkMode ? .dark : .default
    }
    
    //MARK: - Dynamic Memories Settings
    var dynamicMemoriesEnabled: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.enableDynamicMemories.rawValue)
            NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
        }
        get {
            if let value = userDefaults.value(forKey: Key.enableDynamicMemories.rawValue) as? Bool {
                return value
            }
            
            //Set default value to true.
            self.dynamicMemoriesEnabled = true
            return true
        }
    }
    
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
            }
            
            userDefaults.set(newValue.rawValue, forKey: Key.dynamicMemoryUpdatePeriod.rawValue)
            memoriesViewController?.handleDynamicMemory()
        }
        get {
            if let rawValue = userDefaults.value(forKey: Key.dynamicMemoryUpdatePeriod.rawValue) as? String {
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
    
    var addDynamicMemoriesToLibrary: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.addDynamicMemoriesToLibrary.rawValue)
        }
        get {
            if let value = userDefaults.value(forKey: Key.addDynamicMemoriesToLibrary.rawValue) as? Bool {
                return value
            }
            
            //Set default value to true.
            self.addDynamicMemoriesToLibrary = true
            return true
        }
    }
    
    //MARK: - Onboarding
    var onboardingComplete: Bool {
        set {
            userDefaults.set(newValue, forKey: "onboardingComplete")
        }
        get {
            return userDefaults.bool(forKey: "onboardingComplete")
        }
    }
    
    //MARK: - Settings.Option
    ///`Settings.Option`: represents a setting option to display.
    enum Option {
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
        
        var interface: Settings.Interface {
            if self.isApplicationInfo {
                return .none
            }
            if self == .dynamicMemoryTimeLength {
                return .uiTextField
            }
            return .uiSwitch
        }
        
        @available(iOS 13.0, *)
        var displayIconSystemName: String? {
            switch self {
            case .enableDynamicMemories :
                return "pencil.and.outline"
            case .dynamicMemoryTimeLength :
                return "hourglass"
            case .autoAddPlaylists :
                return "text.badge.plus"
            default :
                return nil
            }
        }
        
        @available(iOS 13.0, *)
        var displayIconBackgroundColor: Color? {
            switch self {
            case .enableDynamicMemories :
                return .red
            case .dynamicMemoryTimeLength :
                return .green
            case .autoAddPlaylists :
                return .blue
            default :
                return nil
            }
        }
        
        var displayTitle: String {
            switch self {
            case .enableDynamicMemories :
                return "Enable Dynamic Memories"
            case .dynamicMemoryTimeLength :
                return "Dynamic Memory Duration"
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
                return "Copyright © 2019 Collin DeWaters. All rights reserved."
            }
        }
        
        var subtitle: String? {
            switch self {
            case .enableDynamicMemories :
                return "When enabled, Music Memories will create memories using your listening activity."
            case .dynamicMemoryTimeLength :
                return nil
            case .autoAddPlaylists :
                return "Automatically add dynamic memories to your Apple Music library as a playlist."
            case .darkMode :
                return "Make it dark!"
            case .versionInfo :
                return nil
            case .copyrightInfo :
                return nil
            }
        }
    }
    
    enum Interface {
        case uiSwitch, uiPickerView, uiTextField, none
    }
}

extension UIColor {
    static var text: UIColor {
        return Settings.shared.textColor
    }
    
    static var secondaryText: UIColor {
        return Settings.shared.secondaryTextColor
    }
    
    static var background: UIColor {
        return Settings.shared.backgroundColor
    }
    
    static var secondaryBackground: UIColor {
        return Settings.shared.secondaryBackgroundColor
    }
}
