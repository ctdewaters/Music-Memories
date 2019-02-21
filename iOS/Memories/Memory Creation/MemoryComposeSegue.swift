//
//  MemoryComposeSegue.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryComposeSegue: UIStoryboardSegue {
    
    var back = false

    override func perform() {
        if back {
            //Backward animation.
            
            let source = self.source as! MemoryComposeViewController
            
            let window = UIApplication.shared.keyWindow
            
            //Background animation.
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {
                source.backgroundBlur.effect = nil
            }, completion: nil)
            
            //Title label animation.
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                source.moveTitleLabel(toX: window?.frame.maxX ?? 0)
                source.homeButton.alpha = 0
                source.titleLabel.alpha = 0
            }, completion: nil)
            
            //Subtitle label animation.
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveLinear, animations: {
                source.moveSubtitleLabel(toX: window?.frame.maxX ?? 0)
                source.subtitleLabel.alpha = 0
            }, completion: nil)
            
            //Scroll view animation.
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                source.moveScrollView(toY: window?.frame.maxY ?? 0)
                source.scrollView.alpha = 0
                source.collectionView.alpha = 0
            }) { (complete) in
                if complete {
                    source.dismiss(animated: false, completion: nil)
                }
            }
            
            return
        }
        //Forward animation.
        
        let source = self.source as! MemoriesViewController
        let destination = self.destination as! MemoryComposeViewController
        
        let window = UIApplication.shared.keyWindow
        
        destination.view.frame = window?.frame ?? .zero
        destination.backgroundBlur.effect = nil
        destination.titleLabel.alpha = 0
        destination.subtitleLabel.alpha = 0
        destination.homeButton.alpha = 0
        destination.scrollView.alpha = 0
        
        window?.addSubview(destination.view)
        destination.moveTitleLabel(toX: window?.frame.maxX ?? 0)
        destination.moveSubtitleLabel(toX: window?.frame.maxX ?? 0)
        destination.moveScrollView(toY: window?.frame.maxY ?? 0)
        destination.collectionView.frame = destination.scrollView.bounds
        
        //Background and home button animation.
        UIView.animate(withDuration: 0.65, delay: 0, options: .curveLinear, animations: {
            destination.backgroundBlur.effect = Settings.shared.blurEffect
            destination.homeButton.alpha = 1
        }, completion: nil)
        
        //Title label animation.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            destination.moveTitleLabel(toX: 14)
            destination.titleLabel.alpha = 1
        }, completion: nil)
        
        //Subtitle label animation.
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            destination.moveSubtitleLabel(toX: 14)
            destination.subtitleLabel.alpha = 1
        }, completion: nil)
        
        //Scroll view animation.
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            destination.moveScrollView(toY: 16)
            destination.scrollView.alpha = 1
        }) { (complete) in
            if complete {
                source.present(destination, animated: false, completion: nil)
            }
        }
    }
}
