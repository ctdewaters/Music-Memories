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
import UserNotifications
import GSTouchesShowingWindow_Swift

///Global `WCSession` object.
var wcSession: WCSession?

///Application open settings, for playing or creating a memory.
var applicationOpenSettings: ApplicationOpenSettings?

///Reference to "Main.storyboard".
let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

///Reference to "Onboarding.storyboard".
let onboardingStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)

///Reference to "MemoryCreation.storyboard".
let memoryCreationStoryboard = UIStoryboard(name: "MemoryCreation", bundle: nil)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate {

    //MARK: - Properties.
    ///The retrieved notification settings.
    public static var notificationSettings: UNNotificationSettings?
    
    ///The application window.
    var customWindow: GSTouchesShowingWindow?
    var window: UIWindow? /*{
        get {
            customWindow = customWindow ?? GSTouchesShowingWindow(frame: UIScreen.main.bounds)
            return customWindow
        }
        set {}
    }*/

    ///The id of the last dynamic memory registered for a notification.
    public static var lastDynamicNotificationID: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: "lastDynamicNotificationID")
        }
        get {
            return UserDefaults.standard.string(forKey: "lastDynamicNotificationID")
        }
    }
    
    static let didBecomeActiveNotification = Notification.Name("didBecomeActive")
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    //MARK: - Key Commands
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIMutableKeyCommand(input: "N", modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Create Memory"),
            UIMutableKeyCommand(input: "F", modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Search Albums"),
            UIMutableKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Increase Volume"),
            UIMutableKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Decrease Volume"),
            UIMutableKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Next Track"),
            UIMutableKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .command, action: #selector(self.didRecieveKeyCommand(_:)), discoverabilityTitle: "Previous Track")
        ]
    }
    @objc private func didRecieveKeyCommand(_ keyCommand: UIKeyCommand) {
        if keyCommand.input == "N" {
            self.handleCreateMemoryResponse()
            return
        }
        if keyCommand.input == "F" {
            LibraryViewController.shared?.searchController?.searchBar.becomeFirstResponder()
            return
        }
        if keyCommand.input == UIKeyCommand.inputUpArrow {
            if let view = LibraryViewController.shared?.volumeView.subviews.first as? UISlider {
                view.value += 0.0625
            }
            return
        }
        if keyCommand.input == UIKeyCommand.inputDownArrow {
            if let view = LibraryViewController.shared?.volumeView.subviews.first as? UISlider {
                view.value -= 0.0625
            }
            return
        }
        if keyCommand.input == UIKeyCommand.inputRightArrow {
            MKMusicPlaybackHandler.mediaPlayerController.skipToNextItem()
            return
        }
        if keyCommand.input == UIKeyCommand.inputLeftArrow {
            if MKMusicPlaybackHandler.mediaPlayerController.currentPlaybackTime > 3 {
                MKMusicPlaybackHandler.mediaPlayerController.skipToBeginning()
                return
            }
            MKMusicPlaybackHandler.mediaPlayerController.skipToPreviousItem()
            return
        }
    }

    //MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //Set the current user notification center delegate to the app delegate.
        UNUserNotificationCenter.current().delegate = self
        
        //Setup IQKeyboardManager.
        IQKeyboardManager.sharedManager().enable = true
        
        //UI appearances.
        UITabBar.appearance().tintColor = .theme
        UITabBar.appearance().unselectedItemTintColor = .tertiaryLabel
        UINavigationBar.appearance().tintColor = .theme
        UINavigationBar.appearance().largeTitleTextAttributes =
            [NSAttributedString.Key.foregroundColor : UIColor.navigationForeground]
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.navigationForeground]
        UISwitch.appearance().onTintColor = .theme

        //Setup WatchConnectivity
        if WCSession.isSupported() {
            wcSession = WCSession.default
            wcSession?.delegate = self
            wcSession?.activate()
        }
        
        if !Settings.shared.onboardingComplete {
            Settings.shared.dynamicMemoriesEnabled = false
            //Go to the onboarding storyboard.
            self.window?.rootViewController = onboardingStoryboard.instantiateInitialViewController()
        }
        
        //Turn on retaining managed objects in Core Data.
        MKCoreData.shared.managedObjectContext.retainsRegisteredObjects = true
        
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
        
        //Set badge number to zero.
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        //Check if onboarding is complete, if so, check if the tokens are valid.
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
                        
                        if MKAuth.musicUserTokenRetrievalAttempts < 1 {
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
                            Settings.shared.dynamicMemoriesEnabled = false
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
    }
    
    //MARK: - UserNotifications.
    ///Registers the application to recieve notifications.
    class func registerForNotifications(withCompletion completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        //Request permission to send notifications.
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            //Run completion block.
            completion(granted)
        }
    }
    
    ///Retrieves the UserNotification settings.
    class func retrieveNotificationSettings(withCompletion completion: @escaping (UNNotificationSettings?) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        //Get the notification settings.
        center.getNotificationSettings { (settings) in
            //Set the settings property.
            AppDelegate.notificationSettings = settings
            
            //Run the completion block with no settings if the application is not authorized to schedule notifications.
            guard settings.authorizationStatus == .authorized else {
                completion(nil)
                return
            }
            
            //User authorized notifications.
            completion(settings)
        }
    }
    
    ///Schedules a local notification, given content, an identifier, and a date to send it.
    class func schedule(localNotificationWithContent content: UNNotificationContent, withIdentifier identifier: String, andSendDate sendDate: Date) {
        //Check if the notification settings show the user authorized.
        if AppDelegate.notificationSettings?.authorizationStatus == .authorized {
            //Create and add the request.
            let timeInterval = sendDate.timeIntervalSinceNow
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { (error) in
                if error != nil {
                    print(error?.localizedDescription ?? "Notification Scheduling Error Occurred")
                }
            }
        }
    }
    
    ///Cancels a scheduled notification request, with a given identifier.
    class func cancel(notificationRequestWithIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    //MARK: - UNUserNotificationCenterDelegate.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //Increment badge.
        UIApplication.shared.applicationIconBadgeNumber += 1
        completionHandler([.alert, .sound])
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
            if let memories = memoriesViewController?.retrievedMemories {
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
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
                
        if let messageCode = message["MMMessageCode"] as? Int {
            if messageCode == ApplicationOpenSettings.createCode {
                self.handleCreateMemoryResponse()
            }
        }
        else {
            //Handle memory.
            MKMemory.handleTransfer(withWCSession: wcSession, withDictionary: message) {
                memoriesViewController?.reload()
            }
        }
    }
    
    //MARK: - Open Response Handling
    private func handleCreateMemoryResponse() {
        DispatchQueue.main.async {
            if memoriesViewController != nil {
                memoriesViewController?.tabBarController?.selectedIndex = 1
                //Open the memory creation view.
                
                //TODO: open create memory sequence when signaled from watch.
//                if memoryComposeVC == nil {
//                    homeVC?.performSegue(withIdentifier: "createMemory", sender: nil)
//                }
            }
            else {
                LibraryViewController.shared?.tabBarController?.selectedIndex = 1
                //Set the application open settings to true.
                applicationOpenSettings = ApplicationOpenSettings()
                applicationOpenSettings?.openCreateView = true
            }
        }
    }
}

///`ApplicationOpenSettings`: provides codes received when the application is opening on what action to take.
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
