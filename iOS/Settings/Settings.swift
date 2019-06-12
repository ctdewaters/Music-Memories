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
import Combine

///Handles setting changes for the whole application.
class Settings: BindableObject {
    
    let didChange = PassthroughSubject<Settings, Never>()
    
    ///The shared instance.
    static let shared = Settings()
    
    ///All of the settings to display.
    static let all: [String: [Settings.Option]] = ["Dynamic Memories" : [.enableDynamicMemories, .dynamicMemoryTimeLength, .autoAddPlaylists], "App Info" : [.versionInfo, .copyrightInfo]]
    
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
        didChange.send(self)
    }
    
    //MARK: - Dynamic Memories Settings
    
    var dynamicMemoriesEnabled: Bool {
        set {
            userDefaults.set(newValue, forKey: Key.enableDynamicMemories.rawValue)
            didChange.send(self)
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
            didChange.send(self)
            homeVC?.handleDynamicMemory()
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
            didChange.send(self)
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
            didChange.send(self)
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
