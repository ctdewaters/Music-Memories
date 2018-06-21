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
    
    
    //MARK: Properties.
    ///The memory item to display.
    weak var memoryItem: MKMemoryItem?
    
    weak var mediaItem: MPMediaItem?
    
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup view coloring.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        self.songTitleLabel.textColor = Settings.shared.textColor
        self.artistAlbumLabel.textColor = Settings.shared.textColor
        self.releaseDateLabel.textColor = Settings.shared.accessoryTextColor
        
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
            
            //Reload the memory collection view.
            MemoryViewController.shared?.memoryCollectionView.reload()
            viewController.dismiss(animated: true, completion: nil)
        }
        
        let play = UIPreviewAction(title: "Play", style: .default) { (action, viewController) in
            if let mediaItem = self.mediaItem {
                print(mediaItem)
                MKMusicPlaybackHandler.play(items: [mediaItem])
            }
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
        self.artworkImageView.layer.cornerRadius = 7
        self.artworkImageView.layer.borderWidth = 3
        self.artworkImageView.layer.borderColor = UIColor.themeColor.cgColor
        //Labels.
        self.songTitleLabel.text = mediaItem.title ?? ""
        self.artistAlbumLabel.text = "\(mediaItem.artist ?? "") • \(mediaItem.albumTitle ?? "")"
        self.releaseDateLabel.text = "Released \(self.string(fromDate: mediaItem.releaseDate))"
        
        //Setup property views.
        self.playCountPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .playCount)
        self.dateAddedPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .dateAdded)
        self.lastPlayedPropertyView.setup(withMediaItem: mediaItem, andPropertyType: .lastPlayed)
        
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
