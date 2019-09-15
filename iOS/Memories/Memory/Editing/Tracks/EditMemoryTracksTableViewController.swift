//
//  EditMemoryTracksTableViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/27/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit
import MediaPlayer

///`EditMemoryTracksTableViewController`: View Controller which allows user to add and remove tracks from a `MKMemory`.
class EditMemoryTracksTableViewController: UITableViewController {
    
    //MARK: - Properties
    weak var memory: MKMemory?
    
    ///The media items to display.
    private var mpMediaItems = [MPMediaItem]()
    
    ///The memory items.
    private var memoryItems = [MKMemoryItem]()
    
    private var mediaPicker: MPMediaPickerController?

    //MARK: - UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Register nib.
        let nib = UINib(nibName: "EditMemoryTrackTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "cell")
        
        self.tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        
        //Reload.
        self.reload()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Post reload notifications.
        NotificationCenter.default.post(name: MemoryViewController.reloadNotification, object: nil)
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mpMediaItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? EditMemoryTrackTableViewCell
        cell?.setup(withMediaItem: self.mpMediaItems[indexPath.row])
        cell?.deletionCallback = {
            self.mpMediaItems.remove(at: indexPath.row)
            
            let localMemoryItem = self.memoryItems[indexPath.row]
            localMemoryItem.delete()
            self.memoryItems.remove(at: indexPath.row)
            
            self.tableView.performBatchUpdates({
                self.tableView.deleteRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .middle)
            }) { complete in
                if complete {
                    self.tableView.reloadData()
                }
            }
        }
        return cell ?? UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
    
    //MARK: - Reloading
    func reload() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.memoryItems = Array(self.memory?.items ?? []).sorted(by: { (first, second) -> Bool in
                return first.mpMediaItem?.playCount ?? 0 > second.mpMediaItem?.playCount ?? 0
            })
            self.mpMediaItems = self.memory?.mpMediaItems?.sorted {
                $0.playCount > $1.playCount
            } ?? []
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func addTracks(_ sender: Any) {
        //Setup picker.
        self.mediaPicker = MPMediaPickerController(mediaTypes: .music)
        self.mediaPicker?.delegate = self
        self.mediaPicker?.allowsPickingMultipleItems = true
        self.present(self.mediaPicker!, animated: true, completion: nil)
    }
}

extension EditMemoryTracksTableViewController: MPMediaPickerControllerDelegate {
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        
        DispatchQueue.global(qos: .userInteractive).async {
            for item in mediaItemCollection.items {
                self.memory?.add(mpMediaItem: item)
            }
            DispatchQueue.main.async {
                self.reload()
            }
        }
        
    }
}
