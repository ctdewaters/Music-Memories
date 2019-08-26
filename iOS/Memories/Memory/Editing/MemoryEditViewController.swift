//
//  MemoryEditViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/23/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

///`MemoryEditViewController`: The view controller in charge of editing an `MKMemory` object.
class MemoryEditViewController: UITableViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var imagesContainerView: UIImageView!
    @IBOutlet weak var titleTextView: UITextView!
    @IBOutlet weak var titleCell: UITableViewCell!
    @IBOutlet weak var startDateField: UITextField!
    @IBOutlet weak var endDateField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var descriptionCell: UITableViewCell!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var startDateCell: UITableViewCell!
    @IBOutlet weak var endDateCell: UITableViewCell!
    
    //MARK: - Properties
    ///The memory to edit.
    weak var memory: MKMemory?
    
    ///The images display view.
    var imagesDisplayView: MemoryImagesDisplayView?
    
    ///The date picker for the date fields.
    var datePicker: UIDatePicker?
    
    //Selected start and end dates.
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?

    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //If the memory is dynamic, disable the start and end date selection.
        if self.memory?.isDynamicMemory ?? false {
            self.startDateField.isEnabled = false
            self.endDateField.isEnabled = false
            
            self.startDateCell.isUserInteractionEnabled = false
            self.endDateCell.isUserInteractionEnabled = false
        }
        
        //Setup selected date properties.
        self.selectedStartDate = self.memory?.startDate
        self.selectedEndDate = self.memory?.endDate

        //Initial value setup with supplied memory.
        self.titleTextView.text = self.memory?.title
        self.descriptionTextView.text = self.memory?.desc
        self.startDateField.text = self.memory?.startDate?.shortString
        self.endDateField.text = self.memory?.endDate?.shortString
        self.songCountLabel.text = "\(self.memory?.items?.count ?? 0)"
        
        //Setup date picker.
        self.datePicker = UIDatePicker()
        self.datePicker?.datePickerMode = .date
        self.startDateField.inputView = self.datePicker
        self.endDateField.inputView = self.datePicker
        self.datePicker?.addTarget(self, action: #selector(self.datePickerDidSelectDate), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Setup the images display view.
        self.setupImagesDisplayView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Post reload notifications.
        NotificationCenter.default.post(name: MemoryViewController.reloadNotification, object: nil)
        NotificationCenter.default.post(name: MemoriesViewController.reloadNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "openImages" {
            guard let destination = segue.destination as? EditMemoryImagesCollectionViewController else { return }
            destination.memory = self.memory
        }
    }
    
    //MARK: - Images Display View
    func setupImagesDisplayView() {
        guard let imagesDisplayView = self.imagesDisplayView, let memory = self.memory else {
            //Create a new instance of the images display view.
            guard let memory = self.memory else { return }
            self.imagesDisplayView = MemoryImagesDisplayView(frame: self.imagesContainerView.bounds)
            self.imagesDisplayView?.set(withMemory: memory)
            self.imagesContainerView.addSubview(self.imagesDisplayView!)
            return
        }
        imagesDisplayView.set(withMemory: memory)
    }
    
    
    //MARK: - Cell Selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 0 {
            self.titleTextView.becomeFirstResponder()
        }
        if indexPath.section == 1 && indexPath.row == 1 {
            //Start date cell
            self.startDateField.becomeFirstResponder()
        }
        if indexPath.section == 1 && indexPath.row == 2 {
            //End date cell
            self.endDateField.becomeFirstResponder()
        }
        if indexPath.section == 1 && indexPath.row == 3 {
            self.descriptionTextView.becomeFirstResponder()
        }
    }
    
    //MARK: - Date Picker
    @objc func datePickerDidSelectDate() {
        guard let date = self.datePicker?.date else { return }
        
        if self.startDateField.isFirstResponder {
            //Start date editing.
            self.selectedStartDate = date
            self.startDateField.text = date.shortString
        }
        else {
            //End date editing.
            self.selectedEndDate = date
            self.endDateField.text = date.shortString
        }
    }
    
    //MARK: - IBActions
    @IBAction func done(_ sender: Any) {
    }
}

extension MemoryEditViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text ?? ""
        if textView == self.titleTextView {
            let height = text.height(withConstrainedWidth: textView.frame.width, font: UIFont(name: "SFProRounded-Bold", size: 22) ?? UIFont.systemFont(ofSize: 22))
            self.titleCell.frame.size.height = height
        }
        else if textView == self.descriptionTextView {
            let height = text.height(withConstrainedWidth: textView.frame.width, font: UIFont(name: "SFProRounded-Semibold", size: 16) ?? UIFont.systemFont(ofSize: 16))
            self.descriptionTextView.frame.size.height = height
        }
        
        self.updateTableViewOffset()
    }
    
    // Animate cell, the cell frame will follow textView content
    private func updateTableViewOffset() {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
}

extension MemoryEditViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        let cell = textField == self.startDateField ? self.startDateCell : self.endDateCell
        cell?.contentView.backgroundColor = .theme
        textField.textColor = .white
        
        //Determine start and end date for the date picker.
        if textField == self.endDateField {
            self.datePicker?.minimumDate = self.selectedStartDate
            self.datePicker?.maximumDate = Date()
        }
        else if textField == self.startDateField {
            self.datePicker?.minimumDate = nil
            self.datePicker?.maximumDate = self.selectedEndDate
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let cell = textField == self.startDateField ? self.startDateCell : self.endDateCell
        cell?.contentView.backgroundColor = .clear
        textField.textColor = .secondaryText
    }
}
