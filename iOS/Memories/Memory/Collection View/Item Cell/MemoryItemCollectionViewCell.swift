//
//  MemoryItemCollectionViewCell.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/6/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer
import MarqueeLabel
import ESTMusicIndicator

class MemoryItemCollectionViewCell: UICollectionViewCell {

    //MARK: - IBOutlets
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemInfoLabel: UILabel!
    @IBOutlet weak var accessoryView: UIView!
    @IBOutlet weak var accessoryViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var deleteIcon: UIImageView!
    
    //MARK: Properties
    var isMultiSelected = false
    var nowPlayingIndicator: ESTMusicIndicatorView?
    var nowPlayingBlur: UIVisualEffectView?
    var nowPlayingBlurPropertyAnimator: UIViewPropertyAnimator?
    var successCheckmark: CDHUDSuccessCheckmark?
    var errorEmblem: CDHUDErrorGraphic?

    //MARK: Selection style: the action to take when this cell is selected.
    var selectionStyle: SelectionStyle = .play
    enum SelectionStyle {
        case delete, unselect, play
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
        self.nowPlayingBlurPropertyAnimator?.startAnimation()
        self.nowPlayingBlurPropertyAnimator?.stopAnimation(false)
        self.nowPlayingBlurPropertyAnimator?.finishAnimation(at: .current)
        self.nowPlayingBlurPropertyAnimator = nil

    }
    
    //MARK: Setup
    func set(withMemoryItem item: MKMemoryItem) {
        DispatchQueue.global().async {
            if let mediaItem = item.mpMediaItem {
                DispatchQueue.main.async {
                    self.set(withMPMediaItem: mediaItem)
                }
            }
        }
    }
    
    func set(withMPMediaItem mediaItem: MPMediaItem) {
        //Set up the labels.
        self.itemTitleLabel.text = "\(mediaItem.title ?? "No Title")        "
        self.itemInfoLabel.text = "\(mediaItem.artist ?? "No Artist") • \(mediaItem.albumTitle ?? "No Album Title")        "
        self.itemTitleLabel.textColor = .label
        self.itemInfoLabel.textColor = .secondaryLabel
                
        //Setup the artwork
        DispatchQueue.global(qos: .background).async {
            let artwork = mediaItem.artwork?.image(at: CGSize(width: 50, height: 50))
            DispatchQueue.main.async {
                self.artworkImageView.layer.cornerRadius = 3
                self.artworkImageView.contentMode = .scaleAspectFill
                self.artworkImageView.image = artwork
                self.artworkImageView.backgroundColor = .theme
            }
        }
        
        self.set(selectionStyle: self.selectionStyle)
    }
    
    func set(selectionStyle: SelectionStyle, animated: Bool = false) {
        self.selectionStyle = selectionStyle
        
        if self.selectionStyle == .play {
            self.accessoryViewTrailingConstraint.constant = -48
            self.successCheckmark?.removeFromSuperlayer()
            self.errorEmblem?.removeFromSuperlayer()
                        
            UIView.animate(withDuration: animated ? 0.2 : 0.0001) {
                self.layoutIfNeeded()
            }
        }
        else {
            //Add the correct emblem.
            self.accessoryView.backgroundColor = UIColor.secondarySystemBackground
            self.accessoryView.layer.cornerRadius = 7
            
            //Selection style is unselectable, check if success checkmark has been added.
            if self.selectionStyle == .unselect && self.successCheckmark == nil {
                self.accessoryViewTrailingConstraint.constant = 16

                //Add the checkmark.
                self.successCheckmark = CDHUDSuccessCheckmark(withFrame: CGRect(x: 11, y: 12, width: 17, height: 17), andTintColor: .theme, andLineWidth: 4, withOutlineCircle: false)
                self.accessoryView.layer.addSublayer(self.successCheckmark!)
            }
            else if self.selectionStyle == .delete {
                self.accessoryViewTrailingConstraint.constant = 0

                if self.deleteIcon != nil {
                    self.accessoryView.backgroundColor = .clear
                    self.deleteIcon.isHidden = false
                    self.deleteIcon.tintColor = .gray
                }
            }
            
            UIView.animate(withDuration: animated ? 0.2 : 0.0001) {
                self.layoutIfNeeded()
            }
        }
        
    }
    
    //MARK: Highlighting
    ///Highlights the cell.
    func highlight() {
        UIView.animate(withDuration: 0.05, delay: 0, options: .curveEaseInOut, animations: {
            self.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        }, completion: nil)
    }
    
    ///Unhighlights the cell.
    func removeHighlight() {
        UIView.animate(withDuration: 0.05, delay: 0, options: .curveEaseInOut, animations: {
            self.contentView.transform = .identity
            self.backgroundColor = .clear
        }, completion: nil)
    }
    
    //MARK: - Selection
    func select() {
        self.isMultiSelected = self.isMultiSelected ? false : true
        
        if self.selectionStyle == .unselect {
            //Animate the checkmark.
            self.successCheckmark?.animate(withDuration: 0.3, backwards: !self.isMultiSelected)
        }
    }
    
    //MARK: Now Playing UI
    func toggleNowPlayingUI(_ on: Bool) {
        if !on {
            //Deactivate now playing UI.
            self.nowPlayingIndicator?.state = ESTMusicIndicatorViewState.stopped
            
            UIView.animate(withDuration: 0.25, animations: {
                self.nowPlayingIndicator?.alpha = 0
                self.nowPlayingBlur?.effect = nil
            }) { (complete) in
                if complete {
                    //Deallocate now playing indicator.
                    self.nowPlayingIndicator?.removeFromSuperview()
                    self.nowPlayingIndicator = nil
                    
                    self.nowPlayingBlur?.removeFromSuperview()
                    self.nowPlayingBlur = nil
                    
                    self.nowPlayingBlurPropertyAnimator?.stopAnimation(true)
                    self.nowPlayingBlurPropertyAnimator?.finishAnimation(at: .current)
                    self.nowPlayingBlurPropertyAnimator = nil
                }
            }
            return
        }
        if self.nowPlayingBlur == nil {
            //Activate now playing UI.
            //Setup the blur.
            self.nowPlayingBlur = UIVisualEffectView(effect: nil)
            self.nowPlayingBlur?.frame = self.artworkImageView.bounds
            self.nowPlayingBlur?.frame.origin = .zero
            self.nowPlayingBlur?.alpha = 0
            self.artworkImageView.addSubview(self.nowPlayingBlur!)
            
            //Setup the property animator.
            self.nowPlayingBlurPropertyAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .linear, animations: {
                self.nowPlayingBlur?.effect = UIBlurEffect(style: .systemMaterial)
            })
            self.nowPlayingBlurPropertyAnimator?.fractionComplete = 0.17
            
            //Set up the now playing indicator.
            self.nowPlayingIndicator = ESTMusicIndicatorView(frame: .zero)
            self.nowPlayingIndicator?.tintColor = .theme
            self.nowPlayingIndicator?.sizeToFit()
            self.nowPlayingIndicator?.alpha = 0
            self.nowPlayingIndicator?.center = CGPoint(x: self.nowPlayingBlur!.frame.width / 2, y: self.nowPlayingBlur!.frame.height / 2)
            self.nowPlayingBlur?.contentView.addSubview(self.nowPlayingIndicator!)
            self.nowPlayingIndicator?.state = MKMusicPlaybackHandler.mediaPlayerController.playbackState == MPMusicPlaybackState.paused ? .paused : .playing
            
            //Run the animation.
            UIView.animate(withDuration: 0.5) {
                self.nowPlayingIndicator?.alpha = 1
                self.nowPlayingBlur?.alpha = 1
            }
        }
    }
    
    func updateNowPlayingUIState() {
        self.nowPlayingIndicator?.state = MKMusicPlaybackHandler.mediaPlayerController.playbackState == MPMusicPlaybackState.paused || MKMusicPlaybackHandler.mediaPlayerController.playbackState == MPMusicPlaybackState.stopped ? .paused : .playing
    }
}
