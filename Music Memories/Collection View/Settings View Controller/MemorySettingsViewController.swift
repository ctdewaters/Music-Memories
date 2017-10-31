//
//  MemorySettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/30/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemorySettingsViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var titleStr = ""
    var dateStr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.titleLabel.text = titleStr
        self.dateLabel.text = dateStr
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let cancel = UIPreviewAction(title: "Cancel", style: .default) { (action, viewController) in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        let edit = UIPreviewAction(title: "Edit", style: .default) { (action, viewController) in
            viewController.dismiss(animated: true, completion: nil)
        }
        
        let delete = UIPreviewAction(title: "Delete", style: .destructive) { (action, viewController) in
            viewController.dismiss(animated: true, completion: nil)
            
            homeVC.poppedMemory?.delete()
            homeVC.poppedMemory = nil
            homeVC.reload()
        }
        
        return [cancel, delete]
    }

}
