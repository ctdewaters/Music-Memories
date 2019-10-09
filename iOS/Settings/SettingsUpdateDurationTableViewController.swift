//
//  SettingsUpdateDurationTableViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/12/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class SettingsUpdateDurationTableViewController: UITableViewController {

    let durationOptions: [Settings.DynamicMemoriesUpdatePeriod] = [.Weekly, .Biweekly, .Monthly, .Yearly]
    
    var selectedIndex: Int?
    var originalIndex: Int?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set the selected index.
        for i in 0 ..< self.durationOptions.count {
            if self.durationOptions[i] == Settings.shared.dynamicMemoriesUpdatePeriod {
                self.selectedIndex = i
                self.originalIndex = i
            }
        }

        self.tableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //Update the setting.
        guard let selectedIndex = self.selectedIndex, let originalIndex = self.originalIndex, originalIndex != selectedIndex else { return }
        let selectedDuration = self.durationOptions[selectedIndex]
        
        Settings.shared.dynamicMemoriesUpdatePeriod = selectedDuration
        
        //Update the server settings with this change.
        let serverSettings = Settings.shared.serverSettings
        guard let dynamicMemories = serverSettings.dynamicMemories, let duration = serverSettings.duration, let addToLibrary = serverSettings.addToLibrary else { return }
        
        MKCloudManager.updateUserSettings(dynamicMemories: dynamicMemories, duration: duration, addToLibrary: addToLibrary)
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return durationOptions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SettingsUpdateDurationTableViewCell
        let thisOption = self.durationOptions[indexPath.row]
        
        cell.titleLabel.text = thisOption.rawValue
        
        //If index matches the selected index, this cell has been selected.
        if let selectedIndex = selectedIndex, indexPath.row == selectedIndex {
            cell.select(animated: false)
        }
        else {
            cell.deselect(animated: false)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Select the cell.
        let cell = tableView.cellForRow(at: indexPath) as! SettingsUpdateDurationTableViewCell
        cell.select(animated: true)
        
        //Deselect the previousCell
        guard let selectedIndex = selectedIndex else { return }
        let previousCell = tableView.cellForRow(at: IndexPath(item: selectedIndex, section: 0)) as! SettingsUpdateDurationTableViewCell
        previousCell.deselect(animated: true)
        
        self.selectedIndex = indexPath.row
    }
}

class SettingsUpdateDurationTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedIcon: UIImageView!
    
    
    func select(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.selectedIcon.isHidden = false
            }
            return
        }
        self.selectedIcon.isHidden = false
    }
    
    func deselect(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.15) {
                self.selectedIcon.isHidden = true
            }
            return
        }
        self.selectedIcon.isHidden = true
    }

}
