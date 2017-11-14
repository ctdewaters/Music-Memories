//
//  MemoryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MarqueeLabel

class MemoryViewController: UIViewController {
    
    var memory: MKMemory!
    
    //MARK: - IBOutlets
    @IBOutlet weak var memoryCollectionView: MemoryCollectionView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var closeButton: UIButton!
    
    //MARK - Constraint outlets
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelHeightConstraint: NSLayoutConstraint!
    
    ///The minimum height of the header.
    var minimumHeaderHeight: CGFloat!
    
    ///The maximum height of the header.
    var maximumHeaderHeight: CGFloat!
    
   //The source frame, from which this view was presented.
    var sourceFrame = CGRect.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.minimumHeaderHeight = self.view.safeAreaInsets.top + 115
        self.maximumHeaderHeight = self.view.safeAreaInsets.top + self.view.frame.width

        // Do any additional setup after loading the view.
        self.memoryCollectionView.set(withMemory: memory)
        self.memoryCollectionView.scrollCallback = { offset in
            self.collectionViewDidScroll(withOffset: offset)
        }
        
        //Set title.
        self.titleLabel.text = self.memory.title ?? ""
    }
    
    ///The content inset of the collection view.
    var contentInset: CGFloat!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Determine the background color of the memory collection view.
        self.memoryCollectionView.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Set the content insert of the collection view.
        self.contentInset = self.maximumHeaderHeight  - 40
        self.memoryCollectionView.contentInset.top = contentInset
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Collection view scrolling.
    func collectionViewDidScroll(withOffset offset: CGFloat) {
        //Normalize the offset (to account for the content inset supplied in view will appear).
        let normalizedOffset = offset + contentInset + self.view.safeAreaInsets.top
        self.headerHeightConstraint.constant = self.newHeaderHeight(withOffset: normalizedOffset)
        self.view.layoutIfNeeded()
        
        //The new ratio to apply to the title label font
        let newTitleRatio = self.titleTransform(withOffset: normalizedOffset)
        
        print(newTitleRatio)
        

        //Calculate the new font size
        let newFontSize: CGFloat = !newTitleRatio.isNaN ? 18 + (12 * newTitleRatio) : 30
        
        //Set the new values.
        self.titleLabel.animateToFont(UIFont.systemFont(ofSize:  newFontSize, weight: .bold), withDuration: 0.01)
        
        if !newFontSize.isNaN {
            self.titleLabelHeightConstraint.constant = newFontSize + 5
            self.view.layoutIfNeeded()
        }
    }
    
    //Calculating new header height.
    func newHeaderHeight(withOffset offset: CGFloat) -> CGFloat {
        var newHeight = self.maximumHeaderHeight - offset
        newHeight = newHeight > maximumHeaderHeight ? maximumHeaderHeight : newHeight < minimumHeaderHeight ? minimumHeaderHeight : newHeight
        return newHeight
    }
    
    //Calculating new title transform.
    func titleTransform(withOffset offset: CGFloat) -> CGFloat  {
        //Min and max ratio values.
        let max: CGFloat = 1
        let min: CGFloat = 0
        
        let heightDifference = (self.maximumHeaderHeight - self.minimumHeaderHeight) + 85
        
        var ratio = self.headerHeightConstraint.constant / heightDifference
        
        if ratio > max {
            //Determine rubber banding value.
            let invertedOffset = -offset
            let invertedRatio = invertedOffset / self.maximumHeaderHeight
            
            let rubberBandingRatio = sqrt(invertedRatio) / 2
            
            return max + rubberBandingRatio
        }
        
        //Normalize the ratio.
        ratio = ratio < min ? min : ratio
        
        return ratio
    }
    
    //MARK: - Close button
    @IBAction func close(_ sender: Any) {
        self.performSegue(withIdentifier: "closeMemory", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "closeMemory" {
            let segue = segue as! MemorySegue
            segue.back = true
            segue.sourceFrame = self.sourceFrame
        }
    }
}

extension UILabel {
    ///Animates the label to a new font.
    func animateToFont(_ font: UIFont, withDuration duration: TimeInterval) {
        let oldFont = self.font
        self.font = font
        // let oldOrigin = frame.origin
        let labelScale = oldFont!.pointSize / font.pointSize
        let oldTransform = transform
        transform = transform.scaledBy(x: labelScale, y: labelScale)
        // let newOrigin = frame.origin
        // frame.origin = oldOrigin
        setNeedsUpdateConstraints()
        UIView.animate(withDuration: duration) {
            //    self.frame.origin = newOrigin
            self.transform = oldTransform
            self.layoutIfNeeded()
        }
    }
}
