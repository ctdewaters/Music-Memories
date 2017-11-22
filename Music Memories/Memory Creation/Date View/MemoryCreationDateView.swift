//
//  MemoryComposeDateView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/21/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryCreationDateView: MemoryCreationView {
    
    //MARK: - IBOutlets
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    ///The start date selected.
    var startDate: Date?
    ///The end date selected.
    var endDate: Date?
    
    var selectedTextField: UITextField?
    
    ///The date picker, for date entry into the text fields.
    var datePicker: UIDatePicker!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .date
        self.datePicker.maximumDate = Date()
        self.datePicker.addTarget(self, action: #selector(self.valueChanged(forDatePicker:)), for: .valueChanged)
        
        //Text field setup.
        self.startDateTextField.keyboardAppearance = Settings.shared.keyboardAppearance
        self.endDateTextField.keyboardAppearance = Settings.shared.keyboardAppearance
        self.startDateTextField.inputView = self.datePicker
        self.endDateTextField.inputView = self.datePicker
        self.startDateTextField.delegate = self
        self.endDateTextField.delegate = self
        self.startDateTextField.textColor = Settings.shared.accessoryTextColor
        self.endDateTextField.textColor = Settings.shared.accessoryTextColor
        
        //Label setup.
        self.startDateLabel.textColor = Settings.shared.textColor
        self.endDateLabel.textColor = Settings.shared.textColor
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = Settings.shared.darkMode ? .black : .white
                button.layer.cornerRadius = 10
            }
        }
        self.nextButton.setTitleColor(Settings.shared.textColor, for: .normal)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        for view in self.subviews {
            view.resignFirstResponder()
        }
    }
    
    //MARK: - Date picker value changed.
    @objc func valueChanged(forDatePicker datePicker: UIDatePicker) {
        if let selectedTextField = self.selectedTextField {
            //Set start and end date properties.
            if selectedTextField == self.startDateTextField {
                self.startDate = datePicker.date
            }
            else {
                self.endDate = datePicker.date
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
    
    //MARK: - Button Press
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        if sender == self.backButton {
            memoryComposeVC.dismissView()
        }
        else if sender == self.nextButton {
            //Set the start and end date in the memory being composed.
            memoryComposeVC.memory.startDate = self.startDate
            memoryComposeVC.memory.endDate = self.endDate
        }
        //Go to the next view.
        memoryComposeVC.proceedToNextViewInRoute()
    }
}

extension MemoryCreationDateView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextField = textField
        if textField == self.endDateTextField {
            self.datePicker.minimumDate = self.startDate
        }
    }
}
