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
import DAKeychain
import IQKeyboardManagerSwift
import WatchConnectivity

var wcSession: WCSession?

var applicationOpenSettings: ApplicationOpenSettings?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
    
        //Check tokens.
        MKAuth.testTokens { (valid) in
            //Check if the response is valid.
            if valid {
                //Send retrieved notifications.
                NotificationCenter.default.post(name: MKAuth.developerTokenWasRetrievedNotification, object: nil, userInfo: nil)
                NotificationCenter.default.post(name: MKAuth.musicUserTokenWasRetrievedNotification, object: nil, userInfo: nil)
            }
            else {
                //Reload tokens.
                MKAuth.resetTokens()
                MKAuth.retrieveMusicUserToken()
            }
        }
        
        //Setup WatchConnectivity
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
        
        IQKeyboardManager.sharedManager().enable = true
        
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
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
            memoryComposeVC?.memory?.delete()
    }
    
    //MARK: - Shortcut items
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print(shortcutItem.type)
        if shortcutItem.type == "com.CollinDeWaters.MusicMemories.composeMemory" {
            //Set the open settings to open the memory compose view.
            self.handleCreateMemoryResponse()
        }
        
    }
    
    //MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            print("WCSESSION ACTIVATED")
            
            print(session.isWatchAppInstalled)
            print(session.isPaired)
            
            //Test sending data.
            let dict = ["String" : "SUP"]
            
            do {
                try session.updateApplicationContext(dict)
                
            }
            catch {
                print(error.localizedDescription)
            }

        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSESSION BECAME INACTIVE")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSESSION DEACTIVATED")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let messageCode = message["MMMessageCode"] as? Int {
            if messageCode == ApplicationOpenSettings.createCode {
                self.handleCreateMemoryResponse()
            }
            else if messageCode == ApplicationOpenSettings.deleteCode {
                //Retrieve the memory id to delete in the message.
                if let memoryID = message["memoryID"] as? String {
                    
                }
            }
        }
    }
    
    //MARK: - Open Response Handling
    private func handleCreateMemoryResponse() {
        DispatchQueue.main.async {
            if homeVC != nil {
                //Open the memory creation view.
                if memoryComposeVC == nil {
                    homeVC.performSegue(withIdentifier: "createMemory", sender: nil)
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
