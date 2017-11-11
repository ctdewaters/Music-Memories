//
//  Settings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

///Handles setting changes for the whole application.
class Settings {
    
    ///The shared instance.
    static let shared = Settings()
    
    //User defaults reference.
    let userDefaults = UserDefaults.standard
    
    ///Notification name for settings updated.
    static let didUpdateNotification = Notification.Name("settingsDidUpdate")
    
    fileprivate enum SettingsKey: String {
        case darkMode
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
    var blurEffect: UIBlurEffect {
        return darkMode ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
    }
    
    var accessoryTextColor: UIColor {
        return darkMode ? .lightGray : .darkGray
    }
    
    var textColor: UIColor {
        return darkMode ? .lightText : .darkText
    }

    var barStyle: UIBarStyle {
        return darkMode ? .black : .default
    }
    
}
