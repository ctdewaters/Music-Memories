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
    
    ///The albums to display.
    private var albums = [Int: [MPMediaItemCollection]]()
    
    ///The keys, or years, of the albums dictionary.
    private var keys = [Int]()
    
    ///The index view.
    private var indexView: BDKCollectionIndexView?
    
    //MARK: - UIViewController Overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register cell.
        let cell = UINib(nibName: "AlbumCollectionViewCell", bundle: nil)
        self.collectionView.register(cell, forCellWithReuseIdentifier: "cell")
        
        let sectionHeader = UINib(nibName: "LibrarySectionHeaderView", bundle: nil)
        self.collectionView.register(sectionHeader, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "sectionHeader")
        
        //Load albums.
        LKLibraryManager.shared.retrieveYearlySortedAlbums { (albums) in
            self.albums = albums
            self.keys = albums.keys.sorted {
                $0 > $1
            }
            
            self.collectionView.reloadData()
            
            let indexTitles = self.keys.map {
                return "\("\($0)".suffix(2))"
            }
            self.indexView?.indexTitles = indexTitles
            
        }
        
        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        
        //Table view content inset.
        self.collectionView.contentInset.top = 16
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
        
        //Setup index view.
        self.indexView = BDKCollectionIndexView(frame: .zero, indexTitles: ["nil", "nil"])
        self.indexView?.touchStatusBackgroundColor = .clear
        self.indexView?.touchStatusViewAlpha = 0
        let pointSize = self.indexView?.font.pointSize
        self.indexView?.font = UIFont.systemFont(ofSize: pointSize!, weight: .semibold)
        self.indexView?.addTarget(self, action: #selector(self.indexViewValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(indexView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Setup index view's frame.
        let indexWidth: CGFloat = 20
        let frame = CGRect(x: self.view.frame.size.width - indexWidth, y: 0, width: indexWidth, height: collectionView.frame.size.height * 0.66)
        self.indexView?.frame = frame
        self.indexView?.center.y = self.view.frame.height / 2
        
        //Navigation bar setup.
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        self.hideHairline()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Reset navigation bar.
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
    
    ///Sets up the navigation bar to match the overall design.
    func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.largeTitleDisplayMode = .always
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.tintColor = .theme
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
    }
    
    //MARK: - Settings update function.
    @objc func settingsDidUpdate() {
        //Dark mode
        self.navigationController?.navigationBar.barStyle = Settings.shared.barStyle
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: Settings.shared.darkMode ? UIColor.white : UIColor.theme]
        self.navigationController?.navigationBar.titleTextAttributes = self.navigationController?.navigationBar.largeTitleTextAttributes
        self.tabBarController?.tabBar.barStyle = Settings.shared.barStyle
        
        self.view.backgroundColor = Settings.shared.darkMode ? .black : .white
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
            cell.setup(withAlbum: album)
        }
        return cell
    }
    
    //MARK: - Cell sizing and positioning.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (self.view.frame.width - 60) / 2
        return CGSize(width: width, height: width + 70)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
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
    
    func collectionView(_ collectionView:  UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let album = self.albums[self.keys[indexPath.section]]?[indexPath.item] {
            MKMusicPlaybackHandler.play(items: album.items)
        }
    }
    
    //MARK: - Index scrubbing.
    @objc private func indexViewValueChanged(sender: BDKCollectionIndexView) {
        let path = IndexPath(item: 0, section: Int(sender.currentIndex))
        collectionView.scrollToItem(at: path, at: .top, animated: false)
        collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: collectionView.contentOffset.y - 75)
        
        Haptics.shared.sendImpactHaptic(withStyle: .medium)
    }
}
