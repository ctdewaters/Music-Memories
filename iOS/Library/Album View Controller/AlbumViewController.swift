//
//  AlbumViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import LibraryKit
import MediaPlayer
import MemoriesKit
import SwiftVideoBackground

///`AlbumViewController`: displays the content and information about an album.
class AlbumViewController: MediaCollectionViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var statsView: UIView!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var dateAddedLabel: UILabel!
    @IBOutlet weak var playCountLabel: UILabel!
    @IBOutlet weak var songCountLabel: UILabel!
    
    
    //MARK: - Properties.
    var album: MPMediaItemCollection?
    
    ///If true, nav bar is currently open.
    var navBarIsOpen = false
        
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        self.settingsDidUpdate()
        
        //Register table view cell nib.
        let trackCell = UINib(nibName: "TrackTableViewCell", bundle: nil)
        self.tableView.register(trackCell, forCellReuseIdentifier: "track")
                        
        //Setup video background.
        VideoBackground.shared.removeVideoComposition()
        try? VideoBackground.shared.play(view: self.view, videoName: "albumVCBackground", videoType: "mp4", isMuted: true, willLoopVideo: true)
        VideoBackground.shared.playerLayer.opacity = 0.0
        
        ///Setup.
        self.setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let width = self.view.readableContentGuide.layoutFrame.width
        self.tableViewHeightConstraint.constant = 50.0 * CGFloat(self.album?.items.count ?? 0)
        self.view.layoutIfNeeded()
        
        
        //Scroll View content size.
        var height = width + 95.0
        height += (50.0 * CGFloat(self.album?.items.count ?? 0))
        height += self.statsView.frame.height + self.titleLabel.frame.height + self.subtitleLabel.frame.height
        self.scrollView.contentSize = CGSize(width: 0, height: height)
    }
    
    //MARK: - Setup
    func setup() {
        //Background video and artwork.
        self.setupArtworkAndBackground()
        
        //Labels
        let representativeItem = self.album?.representativeItem
        self.titleLabel.text = representativeItem?.albumTitle ?? ""
        self.subtitleLabel.text = representativeItem?.albumArtist ?? ""
        self.releaseDateLabel.text = representativeItem?.releaseDate?.shortString ?? "N/A"
        self.dateAddedLabel.text = representativeItem?.dateAdded.shortString
        self.songCountLabel.text = self.album?.items.count == 1 ? "1 Song" : "\(self.album?.items.count ?? 0) Songs"
        
        //Play Count
        DispatchQueue.global(qos: .userInteractive).async {
            var count = 0
            
            guard let album = self.album else { return }
            for item in album.items {
                count += item.playCount
            }
            DispatchQueue.main.async {
                self.playCountLabel.text = "\(count)"
            }
        }
        
        self.tableView.reloadData()
    }
    
    /// Sets up the artwork in the artwork image view, and colorizes the video background with the average color of the artwork.
    private func setupArtworkAndBackground() {
        //Album artwork
        let width = self.view.frame.width
        DispatchQueue.global(qos: .userInteractive).async {
            let artwork = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: width / 2))
            DispatchQueue.main.async {
                if self.artworkImageView != nil {
                    self.artworkImageView.image = artwork ?? UIImage(named: "logo500")
                }
            }

            //Artwork average color.
            let thumbnail = self.album?.representativeItem?.artwork?.image(at: CGSize.square(withSideLength: 40))
            let averageColor = thumbnail?.averageColor(alpha: 1.0) ?? .theme
            VideoBackground.shared.apply(colorMultiplyEffectWithColor: CIColor(color: averageColor), inverted: true, flippedVertically: true)
            
            //Fade video background in.
            DispatchQueue.main.async {
                //Set the thumbnail image.
                self.navBarTitleImage.image = thumbnail ?? UIImage(named: "logo500")
                
                //Fade in video background.
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = 0
                animation.toValue = 1
                animation.duration = 0.2
                
                VideoBackground.shared.playerLayer.add(animation, forKey: "fadeIn")
                VideoBackground.shared.playerLayer.opacity = 1.0
            }
        }
    }
    
    //MARK: - Settings Did Update
    @objc func settingsDidUpdate() {
        if #available(iOS 13.0, *) {
            
        }
        else {
            //Dark mode
            self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
            
            //View background color.
            self.view.backgroundColor = .background
            
            self.tableView.separatorColor = .secondaryText
            
            //Info view.
            self.titleLabel.textColor = .navigationForeground
            self.releaseDateLabel.textColor = .text
            self.dateAddedLabel.textColor = .text
        }
    }
    
    @IBAction func openInAppleMusic(_ sender: Any) {
        
    }
}

//MARK: - UITableViewDelegate & DataSource
extension AlbumViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.album?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Track
        let cell = tableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        if let track = self.album?.items[indexPath.row] {
            cell.setup(withItem: track)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < self.album?.items.count ?? 0 {
            DispatchQueue.global().async {
                //Retrieve the array of songs starting at the selected index.
                let array = self.album?.items.subarray(startingAtIndex: indexPath.item)
                
                //Play the array of items.
                MKMusicPlaybackHandler.play(items: array ?? [])
            }
        }
    }
}

//MARK: - Video Background Extension
extension VideoBackground {
    func apply(monochromeColor: CIColor) {
        //Retrieve the player item from the player layer.
        guard let playerItem = self.playerLayer.player?.currentItem else { return }
        playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
            let sourceImage = request.sourceImage.clampedToExtent()
            
            //Create the CIFilter
            guard let filter = CIFilter(name: "CIColorMonochrome", parameters: ["inputImage": sourceImage, "inputColor": monochromeColor, "inputIntensity": 1.0]) else { return }
            filter.setValue(sourceImage, forKey: kCIInputImageKey)
            
            if let output = filter.outputImage?.cropped(to: request.sourceImage.extent) {
                request.finish(with: output, context: nil)
            }
        }
    }
    
    /// Applies a `CIMultiplyCompositing` filter to the video background's frames.
    /// - Parameter color: The color to multiply with the video.
    func apply(colorMultiplyEffectWithColor color: CIColor, inverted: Bool = false, flippedVertically: Bool = false) {
        guard let playerItem = self.playerLayer.player?.currentItem else { return }
        playerItem.videoComposition = AVVideoComposition(asset: playerItem.asset) { request in
            var sourceImage = request.sourceImage.clampedToExtent()
            
            //Generate an image with the inputted color.
            guard let colorFilter = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": color]), let colorImage = colorFilter.outputImage else { return }
            
            //Check if we should invert the source image before continuing.
            if inverted {
                //Contrast to improve the invert filter.
                let contrastFilter = CIFilter(name: "CIColorControls", parameters: ["inputImage": sourceImage, "inputContrast": 2.0, "inputBrightness": 1.0, "inputSaturation": 1.5])
                sourceImage = (contrastFilter?.outputImage ?? sourceImage).clampedToExtent()
                
                //Invert the image with a color invert filter.
                let invertFilter = CIFilter(name: "CIColorInvert", parameters: ["inputImage": sourceImage])
                sourceImage = (invertFilter?.outputImage ?? sourceImage).clampedToExtent()
            }
            //Apply the resulting image to a multiply filter.
            guard let multiplyFilter = CIFilter(name: "CIMultiplyCompositing", parameters: ["inputImage": colorImage, "inputBackgroundImage": sourceImage]) else { return }

            //Create the final output image.
            if var output = multiplyFilter.outputImage?.cropped(to: request.sourceImage.extent) {
                //Flip if specified.
                if flippedVertically {
                    output = output.oriented(.down).cropped(to: request.sourceImage.extent)
                }
                request.finish(with: output, context: nil)
            }
        }
    }
    
    func removeVideoComposition() {
        self.playerLayer.player?.currentItem?.videoComposition = nil
    }
}
