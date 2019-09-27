//
//  LibraryViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/30/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import LibraryKit
import MediaPlayer
import MemoriesKit
import BDKCollectionIndexView

///`LibraryViewController`: displays the user's music library by added date.
class LibraryViewController: UIViewController {
    
    //MARK: - IBOutlets
    ///The collection view.
    @IBOutlet weak var collectionView: UICollectionView!
    
    ///The container view for the year selection slider.
    @IBOutlet weak var yearSelectionSliderContainerView: UIView!
    
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    //MARK: - Properties
    ///The shared instance.
    public static var shared: LibraryViewController?
    
    ///The albums to display.
    private var albums = [Int: [MPMediaItemCollection]]()
    
    ///The keys, or years, of the `albums` dictionary.
    private var keys = [Int]()
        
    ///The selected album.
    private var selectedAlbum: MPMediaItemCollection?
    
    ///The previewed album view controller.
    private var previewedAlbumVC: AlbumViewController?
        
    ///The search controller.
    var searchController: UISearchController?
    
    ///The year selection slider.
    var yearSelectionSlider: CDYearSelectionSlider?
    
    ///A volume view, for changing the system volume level.
    var volumeView = MPVolumeView()
        
    ///If true, the user is currently searching the library.
    private var isSearching: Bool = false
    
    ///The filtered albums.
    private var filteredAlbums = [Int: [MPMediaItemCollection]]()
    
    ///The filtered keys, or years.
    private var filteredKeys = [Int]()
    
    //MARK: - UIViewController Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LibraryViewController.shared = self
        
        //Register cell.
        let cell = UINib(nibName: "AlbumCollectionViewCell", bundle: nil)
        self.collectionView.register(cell, forCellWithReuseIdentifier: "cell")
        
        let sectionHeader = UINib(nibName: "LibrarySectionHeaderView", bundle: nil)
        self.collectionView.register(sectionHeader, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        self.collectionView.contentInset.bottom = CDMiniPlayer.State.closed.size.height + 48.0
        
        //Setup nav bar and search controller.
        self.setupSearchController()
        
        self.hideHairline()
                
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        self.settingsDidUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Setup the year selection slider.
        self.setupYearSelectionSlider()
        
        //Setup the tab bar background.
        let tabBar = self.tabBarController?.tabBar
        tabBar?.barTintColor = .clear
        tabBar?.backgroundImage = UIImage()
                
        //Load albums.
        if self.albums.keys.count == 0 {
            self.collectionView.setContentOffset(CGPoint(x: 0, y: -208), animated: false)
        }
        self.reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //Update the mini player's padding.
        self.updateMiniPlayerPadding()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Reset tab bar.
        let tabBar = self.tabBarController?.tabBar
        tabBar?.backgroundImage = nil
        tabBar?.barTintColor = nil
    }
    
    ///The last recorded width.
    var lastRecordedWidth: CGFloat = 0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.lastRecordedWidth != self.view.frame.width {
            self.lastRecordedWidth = self.view.frame.width
            
            //Update collection view layout.
            let layout = NFMCollectionViewFlowLayout()
            layout.equallySpaceCells = true
            let width = self.cellWidth
            layout.itemSize = CGSize(width: width, height: width + 70)
            layout.minimumInteritemSpacing = 5
            layout.minimumLineSpacing = 10
            self.collectionView.setCollectionViewLayout(layout, animated: true)
            
            //Year selection slider.
            self.yearSelectionSlider?.frame.size.width = self.view.readableContentGuide.layoutFrame.width
            self.yearSelectionSlider?.center = CGPoint(x: self.yearSelectionSliderContainerView.bounds.width / 2, y: self.yearSelectionSliderContainerView.bounds.height / 2)
        }
    }
        
    //MARK: - Supplemental View Setup
    
    //Sets up the search controller.
    func setupSearchController() {
        //Setup the search controller.
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.tintColor = .theme
        self.searchController?.searchBar.delegate = self
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
    }
    
    ///Sets up the index view.
    func setupYearSelectionSlider() {
        //Check if the selection slider has been added, and create it if not.
        if self.yearSelectionSlider == nil {
            self.yearSelectionSlider = CDYearSelectionSlider(width: self.view.readableContentGuide.layoutFrame.width, years: [])
            self.yearSelectionSlider?.sliderDelegate = self
            self.yearSelectionSliderContainerView.addSubview(self.yearSelectionSlider!)
            self.view.bringSubviewToFront(self.navigationController!.navigationBar)
        }
    }
    
    //MARK: - Alerts
    private func setupAlertUI() {
        var requiresAlert = false
        var requiresButton = false
        
        if self.albums.count == 0 {
            let titleFont = UIFont(name: "SFProRounded-Bold", size: 20) ?? UIFont.systemFont(ofSize: 20)
            let subtitleFont = UIFont(name: "SFProRounded-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
            let text = NSMutableAttributedString(string: "Your Library is Empty!", attributes: [NSAttributedString.Key.foregroundColor : UIColor.theme, NSAttributedString.Key.font : titleFont])
            let subtitle = NSAttributedString(string: "\nMusic Memories currently supports local and Apple Music libraries only.", attributes: [NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel, NSAttributedString.Key.font : subtitleFont])
            text.append(subtitle)
            alertLabel.attributedText = text
            requiresAlert = true
        }
        
        if !MKAuth.allowedLibraryAccess {
            alertLabel.text = "Music Memories requires access to your music library for creating and listening to memories."
            requiresAlert = true
            requiresButton = true
        }
                
        self.alertLabel.isHidden = !requiresAlert
        self.openSettingsButton.isHidden = !requiresButton
        self.collectionView.isHidden = requiresAlert
        self.yearSelectionSliderContainerView.isHidden = requiresAlert
        self.searchController?.searchBar.isHidden = requiresAlert
    }
    
    //MARK: - Settings Did Update
    @objc func settingsDidUpdate() {        
        
        //Index view tint color.
        self.yearSelectionSlider?.tint = .theme
    }
    
    //MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "libraryToAlbum" {
            if let destination = segue.destination as? AlbumViewController {
                destination.album = self.selectedAlbum
                destination.isPreviewed = false
                destination.presentationController?.delegate = self
            }
        }
    }
    
    //MARK: - Reloading
    func reload() {
        let count = self.albums[self.keys.first ?? 0]?.count ?? 0
        
        //Load albums.
        LKLibraryManager.shared.retrieveYearlySortedAlbums { (albums) in
            self.albums = albums
            self.keys = albums.keys.sorted {
                $0 > $1
            }
            
            self.setupAlertUI()
            
            if self.albums[self.keys.first ?? 0]?.count != count {
                self.collectionView.reloadData()
                
                self.yearSelectionSlider?.reload(withNewYearCollection: self.keys)
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func openSettings(_ sender: Any) {
        
    }
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.isSearching ? self.filteredKeys.count : self.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Retrieve correct album and key collections.
        let albums = self.isSearching ? self.filteredAlbums : self.albums
        let keys = self.isSearching ? self.filteredKeys : self.keys
        return albums[keys[section]]?.count ?? 0
    }
    
    //MARK: - Cell Setup
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AlbumCollectionViewCell
        //Retrieve correct album and key collections.
        let albums = self.isSearching ? self.filteredAlbums : self.albums
        let keys = self.isSearching ? self.filteredKeys : self.keys

        if indexPath.section < keys.count {
            if let yearAlbums = albums[keys[indexPath.section]] {
                if indexPath.item < yearAlbums.count {
                    let album = yearAlbums[indexPath.item]
                    cell.setup(withAlbum: album, andAlbumArtworkSize: CGSize.square(withSideLength: self.cellWidth))
                }
            }
        }
        return cell
    }
    
    
    var cellWidth: CGFloat {
        if (self.view.frame.width <= 678.0) {
            return (self.view.frame.width - 38) / 2
        }
        if (self.view.frame.width == 981.0) {
            return (self.view.frame.width - 88) / 3
        }
        return (self.view.frame.width - 88) / 4
    }
    
    //MARK: - Cell Sizing and Positioning
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.cellWidth
        
        return CGSize(width: width, height: width + 70)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    //MARK: - Section Header.
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        //Retrieve correct album and key collections.
        let albums = self.isSearching ? self.filteredAlbums : self.albums
        let keys = self.isSearching ? self.filteredKeys : self.keys

        if indexPath.section < keys.count {
            //Retrieve the section header view.
            if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as? LibrarySectionHeaderView {
                sectionHeader.yearLabel.text = "\(keys[indexPath.section])"
                
                if let yearAlbums = albums[keys[indexPath.section]] {
                    sectionHeader.infoLabel.text = "\(yearAlbums.count) Albums"
                }
                return sectionHeader
            }
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 75)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? AlbumCollectionViewCell {
            cell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? AlbumCollectionViewCell {
            cell.unhighlight()
        }

    }
    
    func collectionView(_ collectionView:  UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Retrieve correct album and key collections.
        let albums = self.isSearching ? self.filteredAlbums : self.albums
        let keys = self.isSearching ? self.filteredKeys : self.keys

        if let album = albums[keys[indexPath.section]]?[indexPath.item] {
            self.selectedAlbum = album
            self.performSegue(withIdentifier: "libraryToAlbum", sender: self)
        }
    }
    
    //MARK: - Context Menu Configuration.
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let albumCollection = self.isSearching ? self.filteredAlbums : self.albums
        let keys = self.isSearching ? self.filteredKeys : self.keys
        let key = keys[indexPath.section]
        guard let album = albumCollection[key]?[indexPath.item] else { return nil }
        
        return self.contextMenuConfiguration(withAlbum: album)
    }
    
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            guard let vc = self.previewedAlbumVC else { return }
            vc.isPreviewed = false
            vc.presentationController?.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    private func contextMenuConfiguration(withAlbum album: MPMediaItemCollection) -> UIContextMenuConfiguration {
        let previewProvider = { () -> UIViewController? in
            guard let vc = mainStoryboard.instantiateViewController(identifier: "albumVC") as? AlbumViewController else { return nil }
            vc.album = album
            vc.presentationController?.delegate = self
            vc.isPreviewed = true
            self.previewedAlbumVC = vc
            return vc
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (actions) -> UIMenu? in
            let play = UIAction(title: "Play", image: UIImage(systemName: "play.circle"), identifier: .none, discoverabilityTitle: nil, attributes: [], state: .off) { (action) in
                MKMusicPlaybackHandler.play(items: album.items)
            }
            
            return UIMenu(title: "", image: nil, identifier: .none, options: [], children: [play])
        }
    }
    
    //MARK: UIScrollViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchController?.searchBar.resignFirstResponder()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yContentOffset = scrollView.contentOffset.y + 65.0
        if let indexPath = self.collectionView.indexPathForItem(at: CGPoint(x: 50, y: yContentOffset)) {
            //Choose the correct keys collection.
            let keys = self.isSearching ? self.filteredKeys : self.keys
            
            //Get the year from the keys collection, and the associated section's item count.
            let year = keys[indexPath.section]
            let sectionItemCount = self.collectionView.numberOfItems(inSection: indexPath.section)
            
            //Calculate the step.
            let step = (6 * indexPath.item) / sectionItemCount
            
            //Create the year option object.
            var yearOption = CDYearOption()
            yearOption.year = year
            yearOption.step = step
            
            //Select the year option object in the slider.
            self.yearSelectionSlider?.select(yearOption: yearOption)
        }
    }
    
    //MARK: - Miniplayer Padding
    func updateMiniPlayerPadding() {
        //Update the mini player's padding.
        let padding = (self.tabBarController?.tabBar.frame.height ?? 0) + self.yearSelectionSliderContainerView.frame.height
        self.updateMiniPlayerWithPadding(padding: padding)
    }
    
}

extension LibraryViewController: CDYearSelectionSliderDelegate {
    func yearSelectionSlider(_ slider: CDYearSelectionSlider, didSelectYearOption yearOption: CDYearOption) {
        DispatchQueue.global(qos: .userInteractive).async {
            guard let year = yearOption.year, let step = yearOption.step else { return }
            
            //Retrieve the correct key collection
            let keys = self.isSearching ? self.filteredKeys : self.keys
            
            if let yearIndex = keys.firstIndex(of: year) {

                //Scroll the the item (on the main thread).
                DispatchQueue.main.async {
                    //Calculate the item to scroll to with the step value.
                    let sectionItemCount = self.collectionView.numberOfItems(inSection: yearIndex)
                    //x / itemCount = y / 6
                    let targetItemIndex = Int((sectionItemCount * step) / 6)
                    
                    self.collectionView.scrollToItem(at: IndexPath(item: targetItemIndex, section: yearIndex), at: .centeredVertically, animated: false)
                }
            }
        }
    }
}

extension LibraryViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //Filter all albums into the filtered albums property, in background queue.
        DispatchQueue.global(qos: .userInteractive).async {
            self.isSearching = true
            
            if searchText == "" {
                self.filteredKeys = self.keys
                self.filteredAlbums = self.albums
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
                return
            }

            var keys = [Int]()
            for year in self.keys {
                if let yearAlbums = self.albums[year] {
                    let filteredYearAlbums = yearAlbums.filter {
                        $0.contains(searchText: searchText)
                    }
                    
                    if filteredYearAlbums.count > 0 {
                        self.filteredAlbums[year] = filteredYearAlbums
                        keys.append(year)
                    }
                }
            }
            //Setup filtered keys array.
            self.filteredKeys = keys.sorted {
                $0 > $1
            }
            
            
            //Reload collection view and year selection slider.
            DispatchQueue.main.async {
                self.yearSelectionSlider?.reload(withNewYearCollection: self.filteredKeys)
                self.collectionView.reloadData()
            }
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        //Reset filtered albums and searching properties.
        self.isSearching = false
        self.filteredAlbums.removeAll()
        self.filteredKeys.removeAll()
        
        self.reload()
    }
}

extension LibraryViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        //Update the mini player's padding.
        self.updateMiniPlayerPadding()
    }
}


//MARK: - MediaPlayer search functions.
extension MPMediaItemCollection {
    func contains(searchText: String) -> Bool {
        if let representativeItem = self.representativeItem {
            let terms = searchText.components(separatedBy: " ")
            if representativeItem.contains(terms: terms) {
                return true
            }
        }
        return false
    }
}

extension MPMediaItem {
    func contains(terms: [String]) -> Bool {
        for term in terms {
            if !self.contains(searchText: term) && term != "" {
                return false
            }
        }
        return true
    }
    
    func contains(searchText: String) -> Bool {
        if let albumTitle = self.albumTitle, let artist = self.artist, let genre = self.genre, let title = self.title {
            let searchStrings = [albumTitle, artist, genre, title]
            for searchString in searchStrings {
                if searchString.lowercased().range(of: searchText.lowercased(), options: .literal, range: nil, locale: Locale.current) != nil {
                    return true
                }
            }
        }
        return false
    }
}
