//
//  AppDelegate.swift
//  Music Memories
//
//  Created by Collin DeWaters on 7/6/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import CoreData
import StoreKit
import MemoriesKit
import IQKeyboardManagerSwift
import WatchConnectivity

var wcSession: WCSession?

var applicationOpenSettings: ApplicationOpenSettings?

let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    
    static let didBecomeActiveNotification = Notification.Name("didBecomeActive")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Fetch data daily.
        UIApplication.shared.setMinimumBackgroundFetchInterval(12*60*60)
        
        //Setup IQKeyboardManager.
        IQKeyboardManager.sharedManager().enable = true
        
        //Setup WatchConnectivity
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
        
        if !Settings.shared.onboardingComplete {
            Settings.shared.enableDynamicMemories = false
            //Go to the onboarding storyboard.
            self.window?.rootViewController = onboardingStoryboard.instantiateInitialViewController()
        }

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if Settings.shared.onboardingComplete {            
            DispatchQueue.global().async {
                //Check tokens.
                MKAuth.testTokens { (valid) in
                    
                    //Check if the response is valid.
                    if valid {
                        MKAuth.requestCloudServiceCapabilities {
                            //Send retrieved notifications.
                            NotificationCenter.default.post(name: MKAuth.developerTokenWasRetrievedNotification, object: nil, userInfo: nil)
                            NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil, userInfo: nil)
                        }
                    }
                    else {
                        //Reload tokens.
                        MKAuth.resetTokens()
                        
                        if !MKAuth.musicUserTokenRetrievalAttempted {
                            MKAuth.retrieveMusicUserToken()
                        }
                    }
                }
                
                MKCoreData.shared.saveContext()
                
                //Request cloud service capabilities.
                MKAuth.requestCloudServiceCapabilities {
                    //Disable dynamic memories if user is not an Apple Music subscriber.
                    if !MKAuth.isAppleMusicSubscriber {
                        DispatchQueue.main.async {
                            Settings.shared.enableDynamicMemories = false
                        }
                    }
                }
            }
        }
        
        NotificationCenter.default.post(name: AppDelegate.didBecomeActiveNotification, object: nil)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
            memoryComposeVC?.memory?.delete()
    }
    
    //MARK: - Background fetch.
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Settings.shared.enableDynamicMemories {
            if let currentDynamicMemory = MKCoreData.shared.fetchCurrentDynamicMKMemory() {
                let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 17, maxAddsPerAlbum: 7)
                currentDynamicMemory.update(withSettings: updateSettings) { (success) in
                    if success {
                        completionHandler(.newData)
                    }
                    else {
                        completionHandler(.noData)
                    }
                }
            }
            else {
                //Create new dynamic memory.
                if let newDynamicMemory = MKCoreData.shared.createNewDynamicMKMemory(withEndDate: Date().add(days: Settings.shared.dynamicMemoriesUpdatePeriod.days, months: 0, years: 0) ?? Date(), syncToLibrary: Settings.shared.addDynamicMemoriesToLibrary) {
                    newDynamicMemory.save()
                    let updateSettings = MKMemory.UpdateSettings(heavyRotation: true, recentlyPlayed: false, playCount: 17, maxAddsPerAlbum: 5)
                    newDynamicMemory.update(withSettings: updateSettings) { (success) in
                        if success {
                            completionHandler(.newData)
                        }
                        else {
                            completionHandler(.noData)
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Shortcut items
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print(shortcutItem.type)
        if shortcutItem.type == "com.CollinDeWaters.MusicMemories.composeMemory" && Settings.shared.onboardingComplete {
            //Set the open settings to open the memory compose view.
            self.handleCreateMemoryResponse()
        }
    }
    
    //MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if session.activationState == .activated {
            if let memories = homeVC?.retrievedMemories {
                for memory in memories {
                    memory.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .update)
                }
            }
            else {
                let localMemories = MKCoreData.shared.fetchAllMemories()
                for memory in localMemories {
                    memory.messageToCompanionDevice(withSession: wcSession, withTransferSetting: .update)
                }
            }
        }
        else {
            print("SESSION ACTIVATION ISSUE")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        print("MESSAGE RECIEVED: \n\n\n\n \(message)")
        
        if let messageCode = message["MMMessageCode"] as? Int {
            if messageCode == ApplicationOpenSettings.createCode {
                self.handleCreateMemoryResponse()
            }
        }
        else {
            //Handle memory.
            MKMemory.handleTransfer(withWCSession: wcSession, withDictionary: message) {
                homeVC?.reload()
            }
        }
    }
    
    //MARK: - Open Response Handling
    private func handleCreateMemoryResponse() {
        DispatchQueue.main.async {
            if homeVC != nil {
                //Open the memory creation view.
                if memoryComposeVC == nil {
                    homeVC?.performSegue(withIdentifier: "createMemory", sender: nil)
                }
            }
            else {
                //Set the application open settings to true.
                applicationOpenSettings = ApplicationOpenSettings()
                applicationOpenSettings?.openCreateView = true
            }
        }
    }
}

class ApplicationOpenSettings {
    //Codes
    //When this code is recieved on open, the global applicationOpenSettings object will be initialized with open create view set to true.
    static let createCode = 100
    ///When this code is recieved, we should look for a delete id in the message received from Apple Watch.
    static let deleteCode = 200
    
    ///Open create view setting.
    var openCreateView = false
    
    init() {
    }
}
