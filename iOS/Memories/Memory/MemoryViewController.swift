//
//  MemoryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/5/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer
import SwiftVideoBackground

///`MemoryViewController`: A `MediaCollectionViewController` which displays and provides edit controls for a `MKMemory` object.
class MemoryViewController: MediaCollectionViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var songCountLabel: UILabel!
    
    
    //MARK: - Properties
    ///The memory to display.
    weak var memory: MKMemory?
    
    private lazy var mpMediaItems: [MPMediaItem]? = {
        return self.memory?.mpMediaItems?.sorted {
            return $0.playCount > $1.playCount
        }
    }()
    
    ///The memory images display view, which will display (and animate, if more than four) the images of the associated memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The thumbnail memory images display view.
    var thumbnailMemoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The blur animation property animator.
    var headerBlurPropertyAnimator: UIViewPropertyAnimator?
                
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register table view cell nib.
        let trackCell = UINib(nibName: "TrackTableViewCell", bundle: nil)
        self.tableView.register(trackCell, forCellReuseIdentifier: "track")

        //Setup video background.
        VideoBackground.shared.removeVideoComposition()
        try? VideoBackground.shared.play(view: self.view, videoName: "onboarding", videoType: "mp4", isMuted: true, willLoopVideo: true)
        VideoBackground.shared.apply(orientation: .downMirrored)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Update memory images display view.
        self.memoryImagesDisplayView?.frame = self.artworkImageView.bounds
        self.memoryImagesDisplayView?.reload()
        
        let width = self.view.readableContentGuide.layoutFrame.width
        self.tableViewHeightConstraint.constant = 55.0 * CGFloat(self.mpMediaItems?.count ?? 0)
        self.view.layoutIfNeeded()
        
        
        //Scroll View content size.
        var height = width + 95.0
        height += (55.0 * CGFloat(self.mpMediaItems?.count ?? 0))
        height += 40.0 + self.titleLabel.frame.height + self.subtitleLabel.frame.height + self.descriptionTextView.frame.height
        self.scrollView.contentSize = CGSize(width: 0, height: height)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    //MARK: - Setup
    func setup() {
        //Labels.
        self.titleLabel.text = self.memory?.title ?? ""
        self.descriptionTextView.contentInset = UIEdgeInsets.zero
        self.descriptionTextView.text = self.memory?.desc
        
        if (self.mpMediaItems?.count ?? 0) == 1 {
            self.songCountLabel.text = "1 Song"
        }
        else {
            self.songCountLabel.text = "\((self.mpMediaItems?.count ?? 0)) Songs"
        }
        
        //Date range.
        if let startDate = self.memory?.startDate, let endDate = self.memory?.endDate {
            self.subtitleLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
        }
        else {
            if let startDate = self.memory?.startDate {
                self.subtitleLabel.text = startDate.longString
            }
            else if let endDate = self.memory?.endDate {
                self.subtitleLabel.text = endDate.longString
            }
        }
        
        //Setup the memory images.
        self.setupMemoryImagesDisplayView()
        
        self.tableView.reloadData()
    }
    
    ///Sets up the memory images display view.
    private func setupMemoryImagesDisplayView() {
        guard let memory = self.memory else { return }

        //Setup the main image display view.
        if self.memoryImagesDisplayView == nil {
            //Add the images display view to the images holding view.
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: self.artworkImageView.bounds)
            self.artworkImageView.addSubview(self.memoryImagesDisplayView!)

            //Center it.
            self.memoryImagesDisplayView?.center = CGPoint(x: self.artworkImageView.bounds.width / 2, y: (self.artworkImageView.bounds.height / 2))

            //Set it up with the currently displayed memory.
            self.memoryImagesDisplayView?.set(withMemory: memory)
        }
        
        //Setup the thumbnail.
        if self.thumbnailMemoryImagesDisplayView == nil && (self.memory?.images?.count ?? 0) > 1 {
            self.thumbnailMemoryImagesDisplayView = MemoryImagesDisplayView(frame: self.navBarTitleImage.bounds)
            self.navBarTitleImage.addSubview(self.thumbnailMemoryImagesDisplayView!)
            
            self.thumbnailMemoryImagesDisplayView?.set(withMemory: memory)
        }
    }
    
    //MARK: - IBActions
    @IBAction func play(_ sender: Any) {
        guard let memory = self.memory else { return }
        MKMusicPlaybackHandler.play(memory: memory)
    }
    
    @IBAction func edit(_ sender: Any) {
        
    }
    
    //MARK: - DateIntervalFormatter
    ///Creates and interval string using a start and end date.
    func intervalString(withStartDate startDate: Date, andEndDate endDate: Date) -> String {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: startDate, to: endDate)
    }
}

//MARK: - UITableViewDelegate & DataSource
extension MemoryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mpMediaItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Track
        let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        if let track = self.mpMediaItems?[indexPath.row] {
            cell.setup(withItem: track, andDisplaySetting: .artwork)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < self.mpMediaItems?.count ?? 0 {
            DispatchQueue.global().async {
                //Retrieve the array of songs starting at the selected index.
                let array = self.mpMediaItems?.subarray(startingAtIndex: indexPath.item)
                
                //Play the array of items.
                MKMusicPlaybackHandler.play(items: array ?? [])
            }
        }
    }
}


extension VideoBackground {
    func apply(orientation: CGImagePropertyOrientation) {
        //Retrieve the player item from the player layer.
        guard let playerItem = self.playerLayer.player?.currentItem else { return }
        playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
            request.finish(with: request.sourceImage.oriented(orientation), context: nil)
        }
    }
}
