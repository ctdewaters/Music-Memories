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
                        
        //Setup video background.
        VideoBackground.shared.removeVideoComposition()
        try? VideoBackground.shared.play(view: self.view, videoName: "albumVCBackground", videoType: "mp4", isMuted: true, willLoopVideo: true)
        VideoBackground.shared.playerLayer.opacity = 0.0
                
        //Setup.
        self.setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //Scroll View content size.
        let width = self.view.readableContentGuide.layoutFrame.width
        var height = width + 95.0
        height += (self.tableViewRowHeight * CGFloat(self.album?.items.count ?? 0))
        height += self.statsView.frame.height + self.titleLabel.frame.height + self.subtitleLabel.frame.height
        self.scrollView.contentSize = CGSize(width: 0, height: height)
    }
    
    //MARK: - Setup
    func setup() {
        //Background video and artwork.
        self.setupArtworkAndBackground()
        
        //Setup table view properties.
        self.tableViewRowHeight = 50.0
        self.displaySetting = .trackNumber
        self.showSubtitle = false
        self.items = album?.items ?? []
        
        //Labels
        let representativeItem = self.album?.representativeItem
        self.titleLabel.text = representativeItem?.albumTitle ?? ""
        self.navBarTitleLabel.text = self.titleLabel.text
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
        
    @IBAction func openInAppleMusic(_ sender: Any) {
        
    }
    
    override func close(_ sender: Any) {
        super.close(sender)
        LibraryViewController.shared?.updateMiniPlayerPadding()
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
