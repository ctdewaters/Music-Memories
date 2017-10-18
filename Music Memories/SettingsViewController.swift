//
//  SettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/18/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        //Add blur
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = self.view.frame
        self.tableView.backgroundView = blur

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        return cell
    }
    
    
    //MARK: - IBActions
    @IBAction func close(_ sender: Any) {
        self.performSegue(withIdentifier: "settingsToHome", sender: self)
    }
    
}

//MARK: - Dismissal segue
class SettingsDismissalSegue: UIStoryboardSegue {
    override func perform() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.source.navigationController?.view.frame.origin.y = self.source.view.frame.maxY
        }) { (complete) in
            if complete {
                self.source.dismiss(animated: false, completion: nil)
            }
        }
    }
}
