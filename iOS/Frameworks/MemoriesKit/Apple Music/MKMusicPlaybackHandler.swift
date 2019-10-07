//
//  MKMusicPlaybackHandler.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

///`MKMusicPlaybackHandler`: Handles music playback for `MKMemory` and `MPMediaItem` objects.
public class MKMusicPlaybackHandler {

    public static var mediaPlayerController = MPMusicPlayerController.systemMusicPlayer
    
    //MARK: - Convenience Variables
    public static var nowPlayingItem: MPMediaItem? {
        return MKMusicPlaybackHandler.mediaPlayerController.nowPlayingItem
    }
    
    //MARK: - Playback functions
    
    ///Plays an array of items.
    public class func play(items: [MPMediaItem]) {
        let collection = MPMediaItemCollection(items: items)
        
        self.playMediaPlayerController(withCollection: collection)
    }
    
    ///Plays a MKMemory object's items.
    public class func play(memory: MKMemory) {
        let items = memory.items?.map {
                return $0.mpMediaItem ?? MPMediaItem()
            }.sorted {
                $0.playCount > $1.playCount
        }
        
        if var items = items, items.count > 0 {
            items = items.filter {
                $0.title != nil && $0.albumTitle == nil
            }
            let collection = MPMediaItemCollection(items: items)
            
            self.playMediaPlayerController(withCollection: collection)
        }
    }
    
    ///Handles playback of multiple songs when shuffle is enabled or disabled.
    private class func playMediaPlayerController(withCollection collection: MPMediaItemCollection) {
        var shuffleWasOn = false
        if mediaPlayerController.shuffleMode != .off {
            mediaPlayerController.shuffleMode = .off
            shuffleWasOn = true
        }
        
        mediaPlayerController.setQueue(with: collection)
        
        //Wait for media player, and play the items.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            mediaPlayerController.prepareToPlay()
            mediaPlayerController.play()
            
            if shuffleWasOn {
                mediaPlayerController.shuffleMode = .songs
            }
        }
    }
    
    public init() {
    }
    
}
