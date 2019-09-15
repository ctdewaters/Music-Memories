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
class EditMemoryViewController: UITableViewController {
    
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
                
        //Setup selected date properties.
        self.selectedStartDate = self.memory?.startDate
        self.selectedEndDate = self.memory?.endDate
        
        //If the memory is dynamic, disable the start and end date selection.
        if self.memory?.isDynamicMemory ?? false {
            self.startDateField.isEnabled = false
            self.endDateField.isEnabled = false
            
            self.startDateCell.isUserInteractionEnabled = false
            self.endDateCell.isUserInteractionEnabled = false
            self.startDateCell.contentView.alpha = 0.25
            self.endDateCell.contentView.alpha = 0.25
        }
        
        //Setup date picker.
        self.datePicker = UIDatePicker()
        self.datePicker?.datePickerMode = .date
        self.startDateField.inputView = self.datePicker
        self.endDateField.inputView = self.datePicker
        self.datePicker?.addTarget(self, action: #selector(self.datePickerDidSelectDate), for: .valueChanged)
        
        self.tableView.contentInset.bottom = CDMiniPlayer.State.closed.size.height + 16.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Value setup with supplied memory.
        self.titleTextView.text = self.memory?.title
        self.descriptionTextView.text = self.memory?.desc
        self.startDateField.text = self.memory?.startDate?.shortString
        self.endDateField.text = self.memory?.endDate?.shortString
        self.songCountLabel.text = "\(self.memory?.items?.count ?? 0)"
        
                
        //Setup the images display view.
        self.setupImagesDisplayView()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Update memory metadata.
        self.memory?.title = self.titleTextView.text
        self.memory?.desc = self.descriptionTextView.text
        self.memory?.startDate = self.selectedStartDate
        self.memory?.endDate = self.selectedEndDate
        self.memory?.save(sync: true, withAPNS: true)
        
        //Post reload notifications.
        NotificationCenter.default.post(name: MemoryViewController.reloadNotification, object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "openImages" {
            guard let destination = segue.destination as? EditMemoryImagesCollectionViewController else { return }
            destination.memory = self.memory
        }
        else if segue.identifier == "openSongs" {
            guard let destination = segue.destination as? EditMemoryTracksTableViewController else { return }
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
        if indexPath.section == 3 && indexPath.row == 0 {
            self.showDeleteAlertController()
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
    
    //MARK: - Action Controller
    private func showDeleteAlertController() {
        let alertController = UIAlertController(title: "Delete Memory", message: "This memory will be deleted on all of your signed in devices.", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            //Delete
            self.memory?.delete()
            
            //Dismiss to go back to the memories view controller.
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - IBActions
    @IBAction func done(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension EditMemoryViewController: UITextViewDelegate {
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

extension EditMemoryViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        let cell = textField == self.startDateField ? self.startDateCell : self.endDateCell
        cell?.contentView.backgroundColor = .theme
        textField.textColor = .white
        
        //Determine start and end date for the date picker.
        if textField == self.endDateField {
            self.datePicker?.minimumDate = self.selectedStartDate
            self.datePicker?.maximumDate = Date()
            
            guard let date = self.selectedEndDate else { return }
            self.datePicker?.date = date
        }
        else if textField == self.startDateField {
            self.datePicker?.minimumDate = nil
            self.datePicker?.maximumDate = self.selectedEndDate
            
            guard let date = self.selectedStartDate else { return }
            self.datePicker?.date = date
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let cell = textField == self.startDateField ? self.startDateCell : self.endDateCell
        cell?.contentView.backgroundColor = .clear
        textField.textColor = .secondaryText
    }
}
