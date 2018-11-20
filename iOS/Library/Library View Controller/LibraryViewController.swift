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
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    ///The albums to display.
    private var albums = [Int: [MPMediaItemCollection]]()
    
    ///The keys, or years, of the albums dictionary.
    private var keys = [Int]()
    
    ///The index view.
    private var indexView: BDKCollectionIndexView?
    
    ///The selected album.
    private var selectedAlbum: MPMediaItemCollection?
    
    ///The shared instance.
    public static var shared: LibraryViewController?
    
    ///The search controller.
    private var searchController: UISearchController?
    
    //MARK: - UIViewController Overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LibraryViewController.shared = self
        
        //Register cell.
        let cell = UINib(nibName: "AlbumCollectionViewCell", bundle: nil)
        self.collectionView.register(cell, forCellWithReuseIdentifier: "cell")
        
        let sectionHeader = UINib(nibName: "LibrarySectionHeaderView", bundle: nil)
        self.collectionView.register(sectionHeader, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        //Setup nav bar and search controller.
        self.setupNavigationBar()
        self.setupSearchController()
        
        //Table view content inset.
        self.collectionView.contentInset.top = 16
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        
        //Setup index view.
        self.setupIndexView()
        
        self.filterButton.badgeValue = "1"
        self.filterButton.badgeBGColor = .theme
        self.filterButton.badgeTextColor = .white
        self.filterButton.badgeOriginX -= 2
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Navigation bar setup.
        self.navigationController?.navigationBar.isTranslucent = true
        self.hideHairline()
        
        //Load albums.
        self.reload()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    ///The last recorded width.
    var lastRecordedWidth: CGFloat = 0
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("LAYING OUT SUBVIEWS")
        
        if self.lastRecordedWidth != self.view.frame.width {
            self.lastRecordedWidth = self.view.frame.width
            
            print("RESIZING")
            
            //Update collection view layout.
            let layout = NFMCollectionViewFlowLayout()
            layout.equallySpaceCells = true
            let width = self.cellWidth
            layout.itemSize = CGSize(width: width, height: width + 70)
            layout.minimumInteritemSpacing = 5
            layout.minimumLineSpacing = 10
            self.collectionView.setCollectionViewLayout(layout, animated: true)
            
            //Setup index view's frame.
            let indexWidth: CGFloat = 20
            let frame = CGRect(x: self.view.frame.size.width - indexWidth, y: 0, width: indexWidth, height: collectionView.frame.size.height / 2)
            self.indexView?.frame = frame
            self.indexView?.center.y = self.view.frame.height / 2
        }
    }
    
    ///Sets up the navigation bar to match the overall design.
    func setupNavigationBar() {
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.tintColor = .theme
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
    }
    
    //Sets up the search controller.
    func setupSearchController() {
        //Setup the search controller.
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.dimsBackgroundDuringPresentation = false
        self.searchController?.searchBar.tintColor = .theme
//        self.searchController?.searchBar.delegate = self
        self.searchController?.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = true
        self.navigationItem.searchController = self.searchController
    }
    
    ///Sets up the index view.
    func setupIndexView() {
        self.indexView = BDKCollectionIndexView(frame: .zero, indexTitles: nil)
        self.indexView?.tintColor = Settings.shared.darkMode ? .white : .theme
        self.indexView?.touchStatusBackgroundColor = .clear
        self.indexView?.touchStatusViewAlpha = 0
        let pointSize = (self.indexView?.font.pointSize ?? 0) - 3
        self.indexView?.font = UIFont.systemFont(ofSize: pointSize, weight: .bold)
        self.indexView?.addTarget(self, action: #selector(self.indexViewValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(indexView!)
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        //View background color.
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
        
        //Index view tint color.
        self.indexView?.tintColor = Settings.shared.darkMode ? .white : .theme
        
        //Set status bar.
        UIApplication.shared.statusBarStyle = Settings.shared.statusBarStyle
    }
    
    //MARK: - Segue preparation.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "libraryToAlbum" {
            if let destination = segue.destination as? AlbumViewController {
                destination.album = self.selectedAlbum
            }
        }
    }
    
    //MARK: - Reloading.
    func reload() {
        //Load albums.
        LKLibraryManager.shared.retrieveYearlySortedAlbums { (albums) in
            self.albums = albums
            self.keys = albums.keys.sorted {
                $0 > $1
            }
            
            self.collectionView.reloadData()
            
            let indexTitles = self.keys.map {
                return "'\("\($0)".suffix(2))"
            }
            self.indexView?.indexTitles = indexTitles
            
        }
    }
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.albums[self.keys[section]]?.count ?? 0
    }
    
    //MARK: - Cell creation.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AlbumCollectionViewCell
        if let album = self.albums[self.keys[indexPath.section]]?[indexPath.item] {
            cell.setup(withAlbum: album, andAlbumArtworkSize: CGSize.square(withSideLength: self.cellWidth))
        }
        return cell
    }
    
    
    var cellWidth: CGFloat {
        return (self.view.frame.width <= 678.0) ? (self.view.frame.width - 50) / 2 : (self.view.frame.width == 981.0) ? (self.view.frame.width - 90) / 3 : (self.view.frame.width - 90) / 4
    }
    
    //MARK: - Cell sizing and positioning.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = self.cellWidth
        
        print(width)
        return CGSize(width: width, height: width + 70)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    //MARK: - Section Header.
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeader", for: indexPath) as? LibrarySectionHeaderView {
            sectionHeader.yearLabel.text = "\(self.keys[indexPath.section])"
            
            if let yearAlbums = self.albums[self.keys[indexPath.section]] {
                sectionHeader.infoLabel.text = "\(yearAlbums.count) Albums"
            }
            return sectionHeader
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
        if let album = self.albums[self.keys[indexPath.section]]?[indexPath.item] {
            self.selectedAlbum = album
            self.performSegue(withIdentifier: "libraryToAlbum", sender: self)
        }
    }
    
    //MARK: - Index scrubbing.
    @objc private func indexViewValueChanged(sender: BDKCollectionIndexView) {
        let path = IndexPath(item: 0, section: Int(sender.currentIndex))
        collectionView.scrollToItem(at: path, at: .top, animated: false)
        collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y - 75)
        
        Haptics.shared.sendImpactHaptic(withStyle: .light)
    }
}