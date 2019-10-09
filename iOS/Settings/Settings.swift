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
    
    ///All of the settings to display.
    static var all: [String: [Settings.Option]] {
        if #available(iOS 13.0, *) {
            return ["Dynamic Memories" : [.enableDynamicMemories, .dynamicMemoryDuration, .addDynamicMemoriesToLibrary], "App Info" : [.info, .logo]]
        }
        else {
            return ["Visual": [.darkMode], "Dynamic Memories" : [.enableDynamicMemories, .dynamicMemoryDuration, .addDynamicMemoriesToLibrary], "App Info" : [.info, .logo]]
        }
    }
    
    static var allKeys: [String] {
        if #available(iOS 13.0, *) {
            return ["Dynamic Memories", "App Info"]
        }
        else {
            return ["Visual", "Dynamic Memories", "App Info"]
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
    
    //MARK: - Dark Mode (iOS 12.4 and earlier only).
    
    ///If true, user has enabled dark mode. This value will be ignored in iOS 13 for the system setting.
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
    
    ///The current settings tuple to send to the server in the event of an update.
    var serverSettings: MKCloudSettings {
        return (dynamicMemories: self.dynamicMemoriesEnabled, duration: self.dynamicMemoriesUpdatePeriod.serverID, addToLibrary: self.addDynamicMemoriesToLibrary)
    }
    
    var dynamicMemoriesEnabled: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.enableDynamicMemories.rawValue)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
            }
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
    
    ///`Settings.DynamicMemoriesUpdatePeriod`: Specifies the duration a dynamic memory should be updated for.
    enum DynamicMemoriesUpdatePeriod: String, Identifiable {
                
        case Weekly, Biweekly, Monthly, Yearly
        
        var id: String {
            return self.rawValue
        }
        
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
        
        var serverID: Int {
            switch self {
            case .Weekly :
                return 0
            case .Biweekly :
                return 1
            case .Monthly :
                return 2
            case .Yearly :
                return 3
            }
        }
        
        static func fromServerID(_ id: Int) -> DynamicMemoriesUpdatePeriod? {
            switch id {
            case 0 :
                return .Weekly
            case 1 :
                return .Biweekly
            case 2 :
                return .Monthly
            case 3 :
                return .Yearly
            default :
                return nil
            }
        }
    }
    
    ///The dynamic memories update period (defaults to monthly).
    var dynamicMemoriesUpdatePeriod: DynamicMemoriesUpdatePeriod {
        set {
            if let currentDynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                if let startDate = currentDynamicMemory.startDate {
                    currentDynamicMemory.endDate = startDate.add(days: newValue.days, months: 0, years: 0)
                    currentDynamicMemory.save(sync: true, withAPNS: true)
                }
            }
            
            userDefaults.set(newValue.rawValue, forKey: Key.dynamicMemoryUpdatePeriod.rawValue)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
            }
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
    
    ///If true, dynamic memories will be added to the user's iCloud Music Library when created.
    var addDynamicMemoriesToLibrary: Bool {
        set {
            if let currentDynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                currentDynamicMemory.settings?.updateWithAppleMusic = newValue
                currentDynamicMemory.save()
            }
            userDefaults.set(newValue, forKey: Key.addDynamicMemoriesToLibrary.rawValue)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Settings.didUpdateNotification, object: nil)
            }
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
    enum Option: String, Identifiable {
        
        var id: String {
            return self.rawValue
        }
        
        case enableDynamicMemories, dynamicMemoryDuration, addDynamicMemoriesToLibrary, darkMode, info, logo
        
        var isMemorySetting: Bool {
            if self == .enableDynamicMemories || self == .dynamicMemoryDuration || self == .addDynamicMemoriesToLibrary {
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
            if self == .info || self == .logo {
                return true
            }
            return false
        }
        
        var interface: Settings.Interface {
            if self.isApplicationInfo {
                return .none
            }
            if self == .dynamicMemoryDuration {
                return .uiTextField
            }
            return .uiSwitch
        }
        
        @available(iOS 13.0, *)
        var displayIconSystemName: String? {
            switch self {
            case .enableDynamicMemories :
                return "pencil.and.outline"
            case .dynamicMemoryDuration :
                return "hourglass"
            case .addDynamicMemoriesToLibrary :
                return "text.badge.plus"
            default :
                return nil
            }
        }
        
        var displayIconBackgroundColor: UIColor? {
            switch self {
            case .enableDynamicMemories :
                return .theme
            case .dynamicMemoryDuration :
                return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            case .addDynamicMemoriesToLibrary :
                return #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            default :
                return nil
            }
        }
        
        var displayTitle: String {
            switch self {
            case .enableDynamicMemories :
                return "Dynamic Memories"
            case .dynamicMemoryDuration :
                return "Dynamic Memory Duration"
            case .addDynamicMemoriesToLibrary :
                return "Sync to Library"
            case .darkMode :
                return "Dark Mode"
            case .info :
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    return "Version \(version)"
                }
                return "Version -.-.-"
            default :
                return ""
            }
        }
        
        var subtitle: String? {
            switch self {
            case .enableDynamicMemories :
                return "When enabled, Music Memories will create memories using your listening activity."
            case .dynamicMemoryDuration :
                return "The amount of time a Dynamic Memory will continue to update."
            case .addDynamicMemoriesToLibrary :
                return "Automatically add dynamic memories to your Apple Music library as a playlist."
            case .darkMode :
                return "Make it dark!"
            case .info :
                return "Copyright © 2019 Collin DeWaters. All rights reserved."
            default :
                return  ""
            }
        }
    }
    
    ///`Settings.Interface`: Specifies the correct UI interface for a certain settings option.
    enum Interface {
        case uiSwitch, uiTextField, none
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
