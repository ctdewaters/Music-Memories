//
//  MemoryItemPropertiesViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/21/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer

///`MemoryItemPropertiesViewController`: View controller class that will display the properties of a Memory Item, when 3D Touched.
class MemoryItemPropertiesViewController: UIViewController {
    
    //MARK: - IBOutlets.
    //Memory Item Property Views.
    @IBOutlet weak var playCountPropertyView: MemoryItemPropertyView!
    @IBOutlet weak var dateAddedPropertyView: MemoryItemPropertyView!
    @IBOutlet weak var lastPlayedPropertyView: MemoryItemPropertyView!
    
    //Header views.
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    
    //Action buttons.
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var removeFromMemoryButton: UIButton!
    
    @IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
    
    //MARK: Properties.
    ///The memory item to display.
    weak var memoryItem: MKMemoryItem?
    
    weak var mediaItem: MPMediaItem?
    
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup view coloring.
        self.view.backgroundColor = .background
        self.songTitleLabel.textColor = .text
        self.artistAlbumLabel.textColor = .text
        self.releaseDateLabel.textColor = .secondaryText
        
        //Button corner radius.
        for view in self.view.subviews {
            if let button = view as? UIButton {
                button.layer.cornerRadius = 15
            }
        }
        
        //Setup with memory item.
        self.setup(withMemoryItem: self.memoryItem)
        
        self.preferredContentSize.height = 320
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: - Preview action items.
    override var previewActionItems: [UIPreviewActionItem] {
        let delete = UIPreviewAction(title: "Remove From Memory", style: .destructive) { (action, viewController) in
            self.memoryItem?.delete()
            
            //Remove the media item in the items array.
            MemoryViewController.shared?.memoryCollectionView.itemsArray = nil

            //Reload the memory collection view.
            MemoryViewController.shared?.memoryCollectionView.reload()
            viewController.dismiss(animated: true, completion: nil)
        }
        
        let play = UIPreviewAction(title: "Play", style: .default) { (action, viewController) in
            self.play(self)
            viewController.dismiss(animated: true, completion: nil)
        }
        
        return [play, delete]
    }

    
    //MARK: - Setup function.
    func setup(withMemoryItem memoryItem: MKMemoryItem?) {
        //Retrieve the media item from the memory item.
        guard let mediaItem = memoryItem?.mpMediaItem else {
            return
        }
        
        self.mediaItem = mediaItem
        
        //Setup header.
        //Artwork image view.
        self.artworkImageView.image = mediaItem.artwork?.image(at: CGSize(width: 200, height: 200))
        self.artworkImageView.layer.cornerRadius = 10
        
        //Labels.
        self.songTitleLabel.text = mediaItem.title ?? ""
        self.artistAlbumLabel.text = "\(mediaItem.artist ?? "") • \(mediaItem.albumTitle ?? "")"
        self.releaseDateLabel.text = "Released \(self.string(fromDate: mediaItem.releaseDate))"
        
        //Setup property views.
        self.playCountPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .playCount)
        self.dateAddedPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .dateAdded)
        self.lastPlayedPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .lastPlayed)
        
    }
    
    //MARK: - IBActions.
    @IBAction func play(_ sender: Any) {
        if let mediaItem = self.mediaItem {
            print(mediaItem)
            MKMusicPlaybackHandler.play(items: [mediaItem])
        }
    }
    
    @IBAction func removeFromMemory(_ sender: Any) {
        //Delete the memory item.
        self.memoryItem?.delete()
        
        //Reload the memory collection view.
        self.navigationController?.popViewController(animated: true)
        
        //Remove the media item in the items array.
        MemoryViewController.shared?.memoryCollectionView.itemsArray = nil
        MemoryViewController.shared?.memoryCollectionView.reload()
    }
    
    //MARK: - Button presentation.
    func showButtons() {
        self.playButton.isHidden = false
        self.removeFromMemoryButton.isHidden = false
        self.removeFromMemoryButton.backgroundColor = .secondaryBackground
    }
    
    //MARK: - `DateFormatter`
    func string(fromDate date: Date?) -> String {
        guard let date = date else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(for: date) ?? ""
    }
}
