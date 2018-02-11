//
//  MKMusicPlaybackHandler.swift
//  MemoriesKit
//
//  Created by Collin DeWaters on 11/11/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

public class MKMusicPlaybackHandler {

    public static var mediaPlayerController = MPMusicPlayerController.systemMusicPlayer
    
    ///Plays an array of items.
    public class func play(items: [MPMediaItem]) {
        let storeIDs = items.map {
            return $0.playbackStoreID
        }
        
        mediaPlayerController.setQueue(with: storeIDs)
        mediaPlayerController.nowPlayingItem = items.first
        mediaPlayerController.prepareToPlay()
        mediaPlayerController.play()
    }
    
    ///Plays a MKMemory object's items.
    public class func play(memory: MKMemory) {
        let items = memory.items?.map {
            return $0.mpMediaItem ?? MPMediaItem()
        }
        let storeIDs = items?.map {
            return $0.playbackStoreID
        }
        mediaPlayerController.setQueue(with: storeIDs ?? [])
        mediaPlayerController.nowPlayingItem = items?.first
        mediaPlayerController.prepareToPlay()
        mediaPlayerController.play()
    }
    
    public init() {
    }
    
}
