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
    weak var memory: MKMemory!
    
    ///The memory images display view, which will display (and animate, if more than four) the images of the associated memory.
    var memoryImagesDisplayView: MemoryImagesDisplayView?
    
    ///The blur animation property animator.
    var headerBlurPropertyAnimator: UIViewPropertyAnimator?
                
    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    //MARK: - Setup
    func setup() {
        //Labels.
        self.titleLabel.text = self.memory.title ?? ""
        self.descriptionTextView.contentInset = UIEdgeInsets.zero
        self.descriptionTextView.text = self.memory.desc
        
        //Date range.
        if let startDate = self.memory.startDate, let endDate = self.memory.endDate {
            self.subtitleLabel.text = self.intervalString(withStartDate: startDate, andEndDate: endDate)
        }
        else {
            if let startDate = self.memory.startDate {
                self.subtitleLabel.text = startDate.longString
            }
            else if let endDate = self.memory.endDate {
                self.subtitleLabel.text = endDate.longString
            }
        }
        
        //Setup the memory images.
        self.setupMemoryImagesDisplayView()
    }
    
    ///Sets up the memory images display view.
    private func setupMemoryImagesDisplayView() {
        if self.memoryImagesDisplayView == nil {
            //Add the images display view to the images holding view.
            self.memoryImagesDisplayView = MemoryImagesDisplayView(frame: self.artworkImageView.bounds)
            self.artworkImageView.addSubview(self.memoryImagesDisplayView!)

            //Center it.
            self.memoryImagesDisplayView?.center = CGPoint(x: self.artworkImageView.bounds.width / 2, y: (self.artworkImageView.bounds.height / 2))

            //Set it up with the currently displayed memory.
            self.memoryImagesDisplayView?.set(withMemory: self.memory)
        }
    }
    
    //MARK: - IBActions
    @IBAction func play(_ sender: Any) {
        
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
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
