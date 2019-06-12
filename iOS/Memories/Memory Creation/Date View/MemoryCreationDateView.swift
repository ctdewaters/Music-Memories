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
    @IBOutlet weak var startDateSelectionView: UIView!
    @IBOutlet weak var endDateSelectionView: UIView!
    @IBOutlet weak var separatorLabel: UILabel!
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
        let startDateStr = NSAttributedString(string: "Choose a Start Date...", attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.5)])
        self.startDateTextField.attributedPlaceholder = startDateStr
        let endDateStr = NSAttributedString(string: "Choose an End Date...", attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel.withAlphaComponent(0.5)])
        self.endDateTextField.attributedPlaceholder = endDateStr
        self.startDateTextField.inputView = self.datePicker
        self.endDateTextField.inputView = self.datePicker
        self.startDateTextField.delegate = self
        self.endDateTextField.delegate = self
        self.startDateTextField.textColor = .secondaryLabel
        self.endDateTextField.textColor = .secondaryLabel
        
        //Date selection view setup.
        self.startDateSelectionView.transform = CGAffineTransform(scaleX: 0.001, y: 0.75)
        self.startDateSelectionView.alpha = 0
        self.startDateSelectionView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.45)
        self.startDateSelectionView.layer.cornerRadius = 10
        self.endDateSelectionView.transform = CGAffineTransform(scaleX: 0.001, y: 0.75)
        self.endDateSelectionView.alpha = 0
        self.endDateSelectionView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.45)
        self.endDateSelectionView.layer.cornerRadius = 10
        
        //Label setup.
        self.separatorLabel.textColor = .label
        
        //Button setup.
        for view in self.subviews {
            if let button = view as? UIButton {
                button.backgroundColor = .label
                button.layer.cornerRadius = 10
            }
        }
        self.nextButton.setTitleColor(.systemBackground, for: .normal)
        
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
        //Resign first responder of all views.
        for view in self.subviews {
            view.resignFirstResponder()
        }

        if sender == self.backButton {
            memoryComposeVC?.dismissView()
            return
        }
        if sender == self.nextButton {
            //Set the start and end date in the memory being composed.
            memoryComposeVC?.memory?.startDate = self.startDate
            memoryComposeVC?.memory?.endDate = self.endDate
            
            if self.startDate == nil || self.endDate == nil {
                //Range not created, remove the song suggestions view.
                memoryComposeVC?.removeSuggestionsView()
            }
            else {
                memoryComposeVC?.addSuggestionsView(toIndex: memoryComposeVC!.currentIndex + 1)
            }
        }
        //Go to the next view.
        memoryComposeVC?.proceedToNextViewInRoute(withTitle: self.title ?? "", andSubtitle: "Add a few photos you remember from this memory.")
    }
    
    //MARK: - Text field selection
    func setStartDateField(toSelected selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.startDateSelectionView.alpha = selected ? 1 : 0
            self.startDateSelectionView.transform = selected ? .identity : CGAffineTransform(scaleX: 0.001, y: 0.75)
        }
    }
    
    func setEndDateField(toSelected selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.endDateSelectionView.alpha = selected ? 1 : 0
            self.endDateSelectionView.transform = selected ? .identity : CGAffineTransform(scaleX: 0.001, y: 0.75)
        }
    }
}

extension MemoryCreationDateView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextField = textField
        if textField == self.endDateTextField {
            //Text field is the end date field.
            self.setEndDateField(toSelected: true)
            
            self.datePicker.minimumDate = self.startDate
            return
        }
        //Start date field
        self.datePicker.minimumDate = nil
        self.setStartDateField(toSelected: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.startDateTextField {
            //Start date field.
            self.setStartDateField(toSelected: false)
            return
        }
        //End date field.
        self.setEndDateField(toSelected: false)
    }
}
