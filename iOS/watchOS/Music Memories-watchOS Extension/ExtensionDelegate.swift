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
                if #available(watchOSApplicationExtension 4.0, *) {
                    backgroundTask.setTaskCompletedWithSnapshot(false)
                } else {
                    // Fallback on earlier versions
                    backgroundTask.setTaskCompleted()
                }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    //MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        //Retrieve the memory, using the memory ID from the application context.
        if let memoryID = applicationContext["memoryID"] as? String {
            if let imageData = applicationContext["imageData"] as? Data {
                if let localMemory = MKCoreData.shared.memory(withID: memoryID) {
                    let mkImage = MKCoreData.shared.createNewMKImage()
                    mkImage.imageData = imageData
                    mkImage.memory = localMemory
                    localMemory.save()
                    
                    //Remove id from pending image transfers array.
                    for i in 0..<pendingImageTransferIDs.count {
                        if pendingImageTransferIDs[i] == memoryID {
                            pendingImageTransferIDs.remove(at: i)
                        }
                    }
                    
                    //Reload data in home IC.
                    homeIC?.reload()
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        MKMemory.handleTransfer(withWCSession: wcSession, withDictionary: userInfo) {
            homeIC?.reload()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        MKMemory.handleTransfer(withWCSession: wcSession, withDictionary: message) {
            homeIC?.reload()
        }
    }
}


///MARK: - UIColor extension
extension UIColor {
    static let themeColor = #colorLiteral(red: 0.93728894, green: 0.2049360275, blue: 0.3079802692, alpha: 1)
    static let error = #colorLiteral(red: 0.987575233, green: 0, blue: 0, alpha: 1)
    static let success = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    
}

