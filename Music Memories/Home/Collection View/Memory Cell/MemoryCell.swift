//
//  MemoryCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryCell: UICollectionViewCell {
    
    //MARK: - IBOutlets
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var infoBlur: UIVisualEffectView!
    @IBOutlet weak var songCountBlur: UIVisualEffectView!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var infoBlurHeightConstraint: NSLayoutConstraint!
    
    //MARK: - Visual state
    enum State {
        case dark, light
    }
    
    var state: State {
        set {
            if newValue == .light {
                self.songCountBlur.effect = UIBlurEffect(style: .light)
                self.infoBlur.effect = UIBlurEffect(style: .light)
                self.songCountLabel.textColor = .black
                self.dateLabel.textColor = .black
                self.titleLabel.textColor = .black
                return
            }
            self.songCountBlur.effect = UIBlurEffect(style: .dark)
            self.infoBlur.effect = UIBlurEffect(style: .dark)
            self.songCountLabel.textColor = .white
            self.dateLabel.textColor = .white
            self.titleLabel.textColor = .white
        }
        get {
            if self.songCountBlur.effect == UIBlurEffect(style: .light) {
                return .light
            }
            return .dark
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        //Set corner radius.
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
        self.songCountBlur.layer.cornerRadius = self.songCountBlur.frame.width / 2
        self.songCountBlur.clipsToBounds = true
        
        self.image.backgroundColor = .darkGray
    }
    
    //MARK: - Setup
    func setup(withMemory memory: MKMemory) {
        self.songCountLabel.text = "\(memory.items?.count ?? 0)"
        self.titleLabel.text = memory.title ?? "Unnamed Memory"
    }
    
    //MARK: - Highlighting
    func highlight() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.image.alpha = 0.7
        }
    }
    
    func removeHighlight() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.image.alpha = 1
        }
    }
}
