//
//  MemoryCreationDateSelectionViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/26/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit

/// `MemoryCreationDateSelectionViewController` : Allows user to select a start and end date for a new memory.
class MemoryCreationDateSelectionViewController: UIViewController {    
    //MARK: IBOutlets
    @IBOutlet weak var separatorLabel: UILabel!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var selectedTextField: UITextField?
    
    ///The date picker, for date entry into the text fields.
    var datePicker: UIDatePicker!

    
    //MARK: UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .date
        self.datePicker.maximumDate = Date()
        self.datePicker.addTarget(self, action: #selector(self.valueChanged(forDatePicker:)), for: .valueChanged)
        
        //Text field setup.
        let startDateStr = NSAttributedString(string: "Choose a Start Date...", attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.secondaryText.withAlphaComponent(0.5)])
        self.startDateTextField.attributedPlaceholder = startDateStr
        let endDateStr = NSAttributedString(string: "Choose an End Date...", attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.secondaryText.withAlphaComponent(0.5)])
        self.endDateTextField.attributedPlaceholder = endDateStr
        self.startDateTextField.inputView = self.datePicker
        self.endDateTextField.inputView = self.datePicker
        self.startDateTextField.delegate = self
        self.endDateTextField.delegate = self
        self.startDateTextField.textColor = .secondaryText
        self.endDateTextField.textColor = .secondaryText
        
        //Label setup.
        self.separatorLabel.textColor = .text
        
        //Next button setup.
        self.nextButton.frame.size = CGSize.square(withSideLength: 30)
        self.nextButton.cornerRadius = 15
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.startDateTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.datePicker.minimumDate = nil
        self.datePicker.maximumDate = Date()

        MemoryCreationData.shared.startDate = nil
        MemoryCreationData.shared.endDate = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for view in self.view.subviews {
            view.resignFirstResponder()
        }
    }
    
    //MARK: Date Functions
    @objc func valueChanged(forDatePicker datePicker: UIDatePicker) {
        if let selectedTextField = self.selectedTextField {
            //Set start and end date properties.
            if selectedTextField == self.startDateTextField {
                MemoryCreationData.shared.startDate = datePicker.date
            }
            else {
                MemoryCreationData.shared.endDate = datePicker.date
            }
            //Update selected text field's text.
            selectedTextField.text = self.string(fromDate: datePicker.date)
        }
    }
    
    func string(fromDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    //MARK: IBActions
    @IBAction func next(_ sender: Any) {
        //Check if user entered a start date.
        if MemoryCreationData.shared.startDate == nil {
            //No title entered, display the error HUD.
            let contentType = CDHUD.ContentType.error(title: "You must select a start date!")
            CDHUD.shared.contentTintColor = .error
            CDHUD.shared.present(animated: true, withContentType: contentType, toView: self.view, removeAfterDelay: 1.5)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.startDateTextField.becomeFirstResponder()
            }
            
            return
        }
        
        if MemoryCreationData.shared.endDate == nil {
            MemoryCreationData.shared.endDate = MemoryCreationData.shared.startDate
        }
        
        //Push to next view.
        self.performSegue(withIdentifier: "dateRangePushTitle", sender: nil)
    }
}


extension MemoryCreationDateSelectionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextField = textField
        if textField == self.endDateTextField {
            //Text field is the end date field.
            self.datePicker.minimumDate = MemoryCreationData.shared.startDate
            return
        }
        //Start date field
        self.datePicker.minimumDate = MemoryCreationData.shared.endDate
    }
}

