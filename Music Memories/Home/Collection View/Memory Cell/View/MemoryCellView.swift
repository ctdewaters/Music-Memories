//
//  MemoryCellView.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/3/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

class MemoryCellView: UIView {

    //MARK: - IBOutlets
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var songCountLabel: UILabel!
    @IBOutlet weak var songCountBlur: UIVisualEffectView!
    @IBOutlet weak var infoBlur: UIVisualEffectView!
    @IBOutlet weak var infoBlurHeightConstraint: NSLayoutConstraint!
    
    weak var memory: MKMemory?
    
    var state: MemoryCell.State {
        set {
            if newValue == .light {
                self.songCountBlur.effect = UIBlurEffect(style: .extraLight)
                self.infoBlur.effect = UIBlurEffect(style: .extraLight)
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
            if self.songCountBlur.effect == UIBlurEffect(style: .extraLight) {
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
    
    func setup(withMemory memory: MKMemory) {
        self.memory = memory
        self.songCountLabel.text = "\(memory.items?.count ?? 0)"
        self.titleLabel.text = memory.title ?? "Unnamed Memory"
        self.image.image = memory.images?.first?.uiImage
    }

}
