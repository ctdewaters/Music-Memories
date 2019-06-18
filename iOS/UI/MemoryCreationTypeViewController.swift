//
//  MemoryCreationTypeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/17/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

///`MemoryCreationTypeViewController`: allows the user to specify the process of which to select songs and suggested images for a memory.
class MemoryCreationTypeViewController: UIViewController {
    
    //MARK: IBOutlets
    @IBOutlet weak var calendarEventButtonContentView: UIView!
    @IBOutlet weak var calendarEventButton: UIButton!
    @IBOutlet weak var dateRangeButtonContentView: UIView!
    @IBOutlet weak var dateRangeButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
    //MARK: UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.closeButton.frame.size = CGSize.square(withSideLength: 30)
        self.closeButton.cornerRadius = 15
        
        self.calendarEventButtonContentView.layer.cornerCurve = .continuous
        self.dateRangeButtonContentView.layer.cornerCurve = .continuous
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.calendarEventButtonContentView.alpha = 1
        self.dateRangeButtonContentView.alpha = 1
    }
    
    //MARK: IBActions
    @IBAction func highlightButton(_ sender: UIButton) {
        if sender == self.calendarEventButton {
            self.calendarEventButtonContentView.alpha = 0.5
            return
        }
        self.dateRangeButtonContentView.alpha = 0.5
    }
    
    @IBAction func unhighlightButton(_ sender: UIButton) {
        if sender == self.calendarEventButton {
            self.calendarEventButtonContentView.alpha = 1
            return
        }
        self.dateRangeButtonContentView.alpha = 1
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
