//
//  MKCloudMemory.swift
//  Music Memories
//
//  Created by Collin DeWaters on 9/13/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import RNCryptor
import MediaPlayer
import CoreData

class MKCloudMemory: Codable {
    var title: String!
    var description: String!
    var id: String!
    var isDynamic: Bool!
    var startDate: String?
    var endDate: String?
    var songs = [MKCloudSong]()
    
    ///Initializes with an `MKMemory` object and encrypts sensitive data.
    init(withMKMemory memory: MKMemory) {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        
        guard let memory = moc.object(with: memory.objectID) as? MKMemory else { return }
        
        self.title = memory.title
        self.description = memory.desc
        self.id = memory.storageID?.replacingAnd
        self.isDynamic = memory.isDynamicMemory
        self.startDate = memory.startDate?.serverString
        self.endDate = memory.endDate?.serverString
                
        //Items
        guard let items = memory.items else { return }
        for item in items {
            let song = MKCloudSong(withMKMemoryItem: item)
            self.songs.append(song)
        }

        //Encrypt.
        self.encrypt()
        
        
    }
    
    var jsonRepresentation: Data? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return data
    }
    
    //MARK: - Encryption and Decryption
    private func encrypt() {
        guard let encryptionKey = MKAuth.encryptionKey else { return }
        
        //Title
        if let titleData = self.title?.data(using: .utf8) {
            let encryptedTitle = RNCryptor.encrypt(data: titleData, withPassword: encryptionKey)
            self.title = encryptedTitle.base64EncodedString()
        }
        
        //Description
        if let descriptionData = self.description?.data(using: .utf8) {
            let encryptedDescription = RNCryptor.encrypt(data: descriptionData, withPassword: encryptionKey)
            self.description = encryptedDescription.base64EncodedString()
        }
        
        //Dates
        if let startDateData = self.startDate?.data(using: .utf8) {
            let encryptedStartDate = RNCryptor.encrypt(data: startDateData, withPassword: encryptionKey)
            self.startDate = encryptedStartDate.base64EncodedString()
        }
        
        if let endDateData = self.endDate?.data(using: .utf8) {
            let encryptedEndDate = RNCryptor.encrypt(data: endDateData, withPassword: encryptionKey)
            self.endDate = encryptedEndDate.base64EncodedString()
        }
        
    }
    
    func decrypt() {
        guard let encryptionKey = MKAuth.encryptionKey else { return }
        
        do {
            //Title
            if let encryptedTitleData = Data(base64Encoded: self.title ?? "", options: .ignoreUnknownCharacters) {
                let titleData = try RNCryptor.decrypt(data: encryptedTitleData, withPassword: encryptionKey)
                let title = String(data: titleData, encoding: .utf8)
                self.title = title
            }
                        
            //Dates
            if let encryptedStartDateData = Data(base64Encoded: self.startDate ?? "", options: .ignoreUnknownCharacters) {
                let startDateData = try RNCryptor.decrypt(data: encryptedStartDateData, withPassword: encryptionKey)
                let startDateString = String(data: startDateData, encoding: .utf8)
                self.startDate = startDateString
            }
            
            if let encryptedEndDateData = Data(base64Encoded: self.endDate ?? "", options: .ignoreUnknownCharacters) {
                let endDateData = try RNCryptor.decrypt(data: encryptedEndDateData, withPassword: encryptionKey)
                let endDateString = String(data: endDateData, encoding: .utf8)
                self.endDate = endDateString
            }
            
            //Description
            if let encryptedDescriptionData = Data(base64Encoded: self.description ?? "", options: .ignoreUnknownCharacters) {
                let descriptionData = try RNCryptor.decrypt(data: encryptedDescriptionData, withPassword: encryptionKey)
                let description = String(data: descriptionData, encoding: .utf8)
                self.description = description
            }
        }
        catch {
            
            print(error.localizedDescription)
        }
    }
    
    //MARK: - Local syncing
    /// Syncs the memory with the local data store.
    func saveToLocalDataStore(withCompletion completion: (()->Void)? = nil) {
        
        //Check if the ID has been deleted, and if so return.
        if MKMemory.deletedIDs.contains(self.id ?? "") {
            return
        }

        //Create a background managed object context.
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        
        //Retrieve or create the memory.
        var memory: MKMemory!
        if !MKCoreData.shared.context(moc, containsMemoryWithID: self.id ?? "") {
            //Memory not stored locally, create a new `MKMemory` object and save it.
            memory = MKCoreData.shared.createNewMKMemory(inContext: moc)
        }
        else {
            memory = MKCoreData.shared.memory(withID: self.id, inContext: moc)
        }
        
        moc.perform {
            memory.isDynamic = NSNumber(booleanLiteral: self.isDynamic)
            memory.title = self.title
            memory.desc = self.description
            memory.storageID = self.id
            memory.settings?.syncWithAppleMusicLibrary = false
                        
            //Dates
            if let startDateStr = self.startDate, let startDateVal = startDateStr.date {
                memory.startDate = startDateVal
            }
            if let endDateStr = self.endDate, let endDateVal = endDateStr.date {
                memory.endDate = endDateVal
            }
            
            
            //Update media item list.
            let songItems = self.songs.map { $0.mpMediaItem }.filter { $0 != nil }.map{ $0! }
            
            //Filter the memory items to delete.
            let memoryItems = memory.items ?? Set()
            let itemsToDelete = memoryItems.filter {
                guard let mediaItem = $0.mpMediaItem else { return false }
                return !songItems.contains(mediaItem)
            }
            for item in itemsToDelete {
                item.delete()
            }
            for item in songItems {
                memory.add(mpMediaItem: item)
            }
            
            memory.save()
            
            completion?()
            
            //Retrieve Images
            MKCloudManager.retrieveImageIDs(forMemoryWithID: memory.storageID) { (imageIDs, deletedImageIDs) in
                
                //Create an MOC to save new MKImage objects with.
                let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                moc.parent = MKCoreData.shared.managedObjectContext
                
                guard let tMemory = moc.object(with: memory.objectID) as? MKMemory else { return }
                
                moc.perform {
                    
                    //Delete images
                    var didDelete = false
                    for id in deletedImageIDs {
                        if let mkImage = MKCoreData.shared.image(withID: id, inContext: moc) {
                            mkImage.delete()
                            didDelete = true
                        }
                    }
                    
                    //Post the did sync notification after the images were deleted.
                    if didDelete {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: MKCloudManager.didSyncNotification, object: nil)
                        }
                    }
                    
                    //Filter empty image IDs
                    let imageIDs = imageIDs.filter { $0 != "" }
                    
                    //Retrieve the current image ids for the memory.
                    guard let currentMemoryImages = tMemory.images else { return }
                    let currentMemoryIDs = currentMemoryImages.map { $0.storageID }.filter { $0 != nil && $0 != ""}.map {$0!}
                    
                    //Filter the images to download.
                    let newImages = imageIDs.filter { !currentMemoryIDs.contains($0) }.filter { !MKImage.deletedIDs.contains($0) }
                    
                    //Filter the images to upload.
                    let imagesToUpload = currentMemoryImages.filter { !imageIDs.contains($0.storageID ?? "")}
                    
                    //Download the new images.
                    for image in newImages {
                        MKCloudManager.download(imageWithID: image, forMemory: tMemory)
                    }
                    
                    //Upload images.
                    for image in imagesToUpload {
                        MKCloudManager.upload(mkImage: image)
                    }
                }
            }
        }
    }
}

class MKCloudSong: Codable{
    var title: String!
    var album: String!
    var artist: String!
    
    init(withMKMemoryItem memoryItem: MKMemoryItem) {
        self.title = memoryItem.title?.replacingAnd.urlEncoded ?? ""
        self.album = memoryItem.albumTitle?.replacingAnd.urlEncoded ?? ""
        self.artist = memoryItem.artist?.replacingAnd.urlEncoded ?? ""
    }
    
    //MARK: - MPMediaItem
    var mpMediaItem: MPMediaItem? {
        //Create the predicates with the album name and artist name retrieved from the Apple Music Web API.
        let albumTitlePredicate = MPMediaPropertyPredicate(value: self.album, forProperty: MPMediaItemPropertyAlbumTitle, comparisonType: .contains)
        let albumArtistPredicate = MPMediaPropertyPredicate(value: self.artist, forProperty: MPMediaItemPropertyAlbumArtist, comparisonType: .contains)
        let songTitlePredicate = MPMediaPropertyPredicate(value: self.title, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)
        
        
        //Create the query object, and add the predicates
        let songsQuery = MPMediaQuery.songs()
        songsQuery.addFilterPredicate(albumTitlePredicate)
        songsQuery.addFilterPredicate(albumArtistPredicate)
        songsQuery.addFilterPredicate(songTitlePredicate)
        
        //Retrieve the collections from the query.

        if let song = songsQuery.items?.first {
            return song
        }
        print("COULDNT FIND RESOURCE FOR MKCloudSong with title \(self.title ?? "") and artist \(self.artist ?? "")")
        return songsQuery.items?.first
    }
}

class MKCloudImage {
    var id: String?
    var memoryID: String?
    var data: Data?
    
    init(withMKImage mkImage: MKImage) {
        guard let storageID = mkImage.storageID, let memoryID = mkImage.memory?.storageID, let data = mkImage.imageData else { return }
        self.id = storageID
        self.memoryID = memoryID
        self.data = data
        
        self.encrypt()
    }
    
    init(withData data: Data, id: String, memoryID: String) {
        self.id = id
        self.data = data
        self.memoryID = memoryID
        
        self.decrypt()
    }
    
    
    //MARK: - Encryption & Decryption
    private func encrypt() {
        guard let encryptionKey = MKAuth.encryptionKey, let data = self.data else { return }
        
        let encryptedImage = RNCryptor.encrypt(data: data, withPassword: encryptionKey)
        self.data = encryptedImage
    }
    
    private func decrypt() {
        guard let encryptionKey = MKAuth.encryptionKey, let data = self.data else { return }
        
        do {
            let decryptedImage = try RNCryptor.decrypt(data: data, withPassword: encryptionKey)
            self.data = decryptedImage
        }
        catch {
            print(error)
        }
    }
    
    //MARK: - Core Data
    func save(toMemory memory: MKMemory) {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = MKCoreData.shared.managedObjectContext
        guard let aMemory = moc.object(with: memory.objectID) as? MKMemory, let data = self.data else { return }
        
        moc.perform {
            let newImage = MKCoreData.shared.createNewMKImage(inContext: moc)
            if let image = UIImage(data: data) {
                newImage.set(withUIImage: image)
            }
            
            newImage.storageID = self.id
            newImage.memory = aMemory
            newImage.save()
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: MKCloudManager.didSyncNotification, object: nil)
            }
        }
    }
}

extension String {
    var removingAnd: String {
        return self.replacingOccurrences(of: "&", with: "")
    }
    
    var replacingAnd: String {
        return self.replacingOccurrences(of: "&", with: "%26")
    }
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
    
    var base64: String {
        let data = self.data(using: .utf8, allowLossyConversion: false)!
        return data.base64EncodedString()
    }
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.A"

        return formatter.date(from: self)
    }
}

fileprivate extension Date {
    var serverString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.A"
        return formatter.string(from: self)
    }
}
