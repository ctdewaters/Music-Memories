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

///`LibraryViewController`: displays the user's music library by added date.
class LibraryViewController: UIViewController {
    
    //MARK: - IBOutlets
    ///The collection view.
    @IBOutlet weak var collectionView: UICollectionView!
    
    ///The albums to display.
    private var albums = [Int: [MPMediaItemCollection]]()
    
    ///The keys, or years, of the albums dictionary.
    private var keys = [Int]()
    
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
        }
        
        // Do any additional setup after loading the view.
        self.setupNavigationBar()
        
        //Table view content inset.
        self.collectionView.contentInset.top = 16
        
        //Add observer for settings changed notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.settingsDidUpdate), name: Settings.didUpdateNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        let width = (self.view.frame.width - 48) / 2
        return CGSize(width: width, height: width + 70)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
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

}
