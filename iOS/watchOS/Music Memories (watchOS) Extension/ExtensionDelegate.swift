//
//  ExtensionDelegate.swift
//  Music Memories (watchOS) Extension
//
//  Created by Collin DeWaters on 2/7/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import WatchKit
import WatchConnectivity
import MemoriesKit_watchOS

var wcSession: WCSession?

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
                
        //Activate WCSession.
        //Check if WatchConnectivity is supported.
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    //MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("SESSION ACTIVATED")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        self.handle(incomingMemory: userInfo)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        self.handle(incomingMemory: message)
    }
    
    //MARK: - Incoming Memory Handling.
    func handle(incomingMemory memoryDict: [String: Any]) {
        //Get the storage ID for the transferred memory.
        if let storageID = memoryDict["storageID"] as? String {
            //Get the transfer setting.
            if let transferSettingRaw = memoryDict["transferSetting"] as? Int {
                if let transferSetting = MKMemory.TransferSetting(rawValue: transferSettingRaw) {
                    if transferSetting == .update {
                        print("UPDATING")
                        if !MKCoreData.shared.contextContains(memoryWithID: storageID) {
                            //Create the memory.
                            let memory = MKMemory(withDictionary: memoryDict)
                            print(memory.storageID)
                            memory.save()
                        }
                    }
                    else if transferSetting == .delete {
                        //Delete the object with the transferred storage ID.
                        MKCoreData.shared.deleteMemory(withID: storageID)
                    }
                    //Reload the main interface controller.
                    mainIC?.reload()
                }
            }
        }
    }

}


///MARK: - UIColor extension
extension UIColor {
    static let themeColor = #colorLiteral(red: 1, green: 0.144608438, blue: 0.3285058141, alpha: 1)
    static let error = #colorLiteral(red: 1, green: 0.1346225441, blue: 0.005045979749, alpha: 1)
    static let success = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    
}
