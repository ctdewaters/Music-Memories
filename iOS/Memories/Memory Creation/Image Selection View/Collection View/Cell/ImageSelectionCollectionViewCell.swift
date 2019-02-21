//
//  ImageSelectionCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/22/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class ImageSelectionCollectionViewCell: UICollectionViewCell {
    //MARK: - IBOutlets
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    //MARK: - Properties
    ///The loading indicator.
    var loadingIndicator: UIActivityIndicatorView?
    
    var deleteCallback: (()->Void)?
    
    var index = 0
    
    //MARK: - UICollectionViewCell overrides
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        self.deleteButton.layer.cornerRadius = 22 / 2
        self.layer.cornerRadius = 11
        
        self.deleteButton.addTarget(self, action: #selector(self.deleteButtonPressed), for: .touchUpInside)
    }

    //MARK: - Delete button
    @objc func deleteButtonPressed() {
        self.deleteCallback?()
    }
    
    //MARK: - Activity indicator.
    func showActivityIndicator(_ show: Bool) {
        if show {
            if self.loadingIndicator == nil {
                self.imageView.image = nil
                self.loadingIndicator = UIActivityIndicatorView(frame: self.bounds)
                self.loadingIndicator?.tintColor = Settings.shared.textColor
                self.addSubview(self.loadingIndicator!)
                self.loadingIndicator?.startAnimating()
            }
        }
        else {
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.loadingIndicator = nil
        }
    }
    
}
