//
//  NotificationViewController.swift
//  Dynamic Memory Notification
//
//  Created by Collin DeWaters on 6/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
    
    //MARK: - IBOutlets.
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        self.preferredContentSize.height = 130
    }
    
    //MARK: - UNNotificationContentExtension.
    func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        
        let startDate = content.userInfo["startDate"] as? Date
        let endDate = content.userInfo["endDate"] as? Date
        
        //Setup date label.
        var dateLabelString = ""
        if let startDate = startDate, let endDate = endDate {
            dateLabelString = self.intervalString(withStartDate: startDate, andEndDate: endDate)
        }
        else {
            if let startDate = startDate {
                dateLabelString = self.string(forDate: startDate)
            }
            else if let endDate = endDate {
                dateLabelString = self.string(forDate: endDate)
            }
        }
        self.dateLabel.text = dateLabelString
        
        //Setup body label.
        self.bodyLabel.text = content.body
    }
    
    //MARK: - DateIntervalFormatter.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
    
    func string(forDate date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
