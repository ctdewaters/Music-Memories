//
//  NumberPickerView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/31/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class NumberPickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    var rowWidth: CGFloat = 60
    
    var rowSelectionCallback: ((String) -> Void)?
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.dataSource = self
        self.delegate = self
    }
    
    //MARK: - UIPickerViewDelegate & DataSource
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return rowWidth
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 25
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 100
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.rowSelectionCallback?("\(row + 1)")
    }

}
