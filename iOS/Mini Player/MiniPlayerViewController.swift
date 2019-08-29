//
//  MiniPlayerViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/28/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MediaPlayer

/// `MiniPlayerViewController`: Provides playback controls for currently playing song.
class MiniPlayerViewController: UIViewController {
    
    ///The window to present the miniplayer in.
    var window: UIWindow? {
        return UIWindow.key
    }
    
    ///The controller's view casted as a `MiniPlayer`.
    var miniPlayer: MiniPlayer {
        return self.view as! MiniPlayer
    }
    
    ///The shared instance.
    public static let shared = MiniPlayerViewController()
    
    ///A notification that will signal the `MiniPlayerViewController` to change the vertical position of the closed `MiniPlayer`.
    public static let miniPlayerVerticalClosedPositionDidChange = Notification.Name("miniPlayerVerticalClosedPositionDidChange")
    
    //MARK: - Initialization
    init() {
        super.init(nibName: "MiniPlayerViewController", bundle: nil)
        
        //Add notification observers.
        NotificationCenter.default.addObserver(self, selector: #selector(self.bottomPaddingDidChange(withNotification:)), name: Notification.Name.miniPlayerBottomPaddingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaPlaybackStateChanged), name: Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.mediaPlaybackItemChanged), name: Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.window?.addSubview(self.miniPlayer)
        self.miniPlayer.layer.zPosition = .greatestFiniteMagnitude
        self.miniPlayer.update(withState: .disabled, animated: false)
        self.miniPlayer.update(withState: .closed)
    }
    
    //MARK: - UIViewController Overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        guard let readableWidth = self.window?.readableContentGuide.layoutFrame.width else { return }
        self.view.frame.size.width = readableWidth
    }
    
    //MARK: - Notification Observer Functions
    @objc private func bottomPaddingDidChange(withNotification notification: Notification) {
        guard let newPadding = notification.userInfo?["padding"] as? CGFloat else { return }
        
        self.miniPlayer.update(padding: newPadding)
    }
    
    @objc private func mediaPlaybackStateChanged() {
        let state = MPMusicPlayerController.systemMusicPlayer.playbackState
    }
    
    @objc private func mediaPlaybackItemChanged() {
        
    }
}

extension Notification.Name {
    ///A notification that will signal the `MiniPlayerViewController` to change the vertical position of the closed `MiniPlayer`.
    public static let miniPlayerBottomPaddingDidChange = Notification.Name("miniPlayerVerticalClosedPositionDidChange")
}
