//
//  AddMemoryCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class AddMemoryCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var blur: UIVisualEffectView!
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        //Set corner radius
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }
    
    //MARK: - State: the visual state of the cell.
    enum State {
        case darkBlur, lightBlur, dark, light
        
        var isDark: Bool {
            if self == .darkBlur || self == .dark {
                return true
            }
            return false
        }
        
        var isBlur: Bool {
            if self == .darkBlur || self == .lightBlur {
                return true
            }
            return false
        }
    }
    
    var state: AddMemoryCell.State {
        set {
            blur.isHidden = !(newValue == .darkBlur || newValue == .lightBlur)
            if newValue == .darkBlur {
                blur.effect = UIBlurEffect(style: .dark)
            }
            else if newValue == .lightBlur {
                blur.effect = UIBlurEffect(style: .light)
            }
            
            if newValue.isDark {
                if !newValue.isBlur {
                    self.backgroundColor = UIColor.black
                }
                self.icon.tintColor = .white
                self.label.textColor = .white
            }
            else {
                if !newValue.isBlur {
                    self.backgroundColor = UIColor.white
                }
                self.icon.tintColor = .black
                self.label.textColor = .black
            }
        }
        get {
            if !self.blur.isHidden {
                if self.blur.effect == UIBlurEffect(style: .dark) {
                    return .darkBlur
                }
                return .lightBlur
            }
            if self.label.textColor == .white {
                return .dark
            }
            return .light
        }
    }
    
    func highlight() {
        //Animate to new transforms.
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 0.87, y: 0.87)
            self.icon.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.label.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            
            if self.state.isBlur {
                if self.state.isDark {
                    self.backgroundColor = UIColor.white.withAlphaComponent(0.25)
                }
                else {
                    self.backgroundColor = UIColor.black.withAlphaComponent(0.25)
                }
            }
            else {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.75)
            }
        }
    }
    
    func removeHighlight() {
        //Animate to new transforms.
        UIView.animate(withDuration: 0.15) {
            self.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.icon.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.label.transform = CGAffineTransform(scaleX: 1, y: 1)
            
            if self.state.isBlur {
                if self.state.isDark {
                    self.backgroundColor = UIColor.clear
                }
                else {
                    self.backgroundColor = UIColor.clear
                }
            }
            else {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(1)
            }
        }
    }
}
