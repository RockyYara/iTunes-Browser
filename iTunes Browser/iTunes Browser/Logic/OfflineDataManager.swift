//
//  OfflineDataManager.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/16/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import CoreData
import ITunesBrowsing

class OfflineDataManager {
    
    static let sharedInstance = OfflineDataManager()

    private(set) var items = [Item]()
    
    // MARK: - Core Data stack initialization
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "iTunes_Browser")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
        })
        
        return container
    }()
    
    private lazy var context: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    // MARK: - Core Data Saving support
    
    // Saves changes in the managed object context.
    func saveData() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    // MARK: - Data Access
    
    private func offlineItem(of type: ItemType, with trackId: Int) -> OfflineItem? {
        let fetchRequest = NSFetchRequest<OfflineItem>(entityName: "OfflineItem")
        fetchRequest.predicate = NSPredicate(format: "type = %@ AND trackId = %@", argumentArray: [type.rawValue, trackId])
        
        if let results = try? context.fetch(fetchRequest) as [OfflineItem], results.count > 0 {
            return results[0]
        } else {
            return nil
        }
    }
    
    private func offlineItems(of type: ItemType) -> [OfflineItem] {
        let fetchRequest = NSFetchRequest<OfflineItem>(entityName: "OfflineItem")
        fetchRequest.predicate = NSPredicate(format: "type = %@", argumentArray: [type.rawValue])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "trackName", ascending: true)]
        
        if let results = try? context.fetch(fetchRequest) as [OfflineItem] {
            return results
        } else {
            return [OfflineItem]()
        }
    }
    
    func saveOrUpdateItem(_ item: Item) {
        if let existingItem = offlineItem(of: item.type, with: item.trackId) {
            existingItem.trackName = item.trackName
            existingItem.artistName = item.artistName
            
            existingItem.image = item.image?.grayscaled()?.pngData()

            print("Updated existing")
        } else {
            let newItem = OfflineItem(context: context)
            
            newItem.type = item.type.rawValue
            newItem.trackId = Int64(item.trackId)
            newItem.trackName = item.trackName
            newItem.artistName = item.artistName

            newItem.image = item.image?.grayscaled()?.pngData()

            print("Saved new")
        }
        
        // I prefer to save Core Data context as soon as possible, for example for cases of unexpected app termination (like Stop command sent from Xcode).
        saveData()
    }
    
    private func deleteOfflineItem(_ offlineItem: OfflineItem) {
        context.delete(offlineItem)

        print("Deleted")

        // I prefer to save Core Data context as soon as possible, for example for cases of unexpected app termination (like Stop command sent from Xcode).
        saveData()
    }
    
}

extension OfflineDataManager: OfflineItemsManager {
    func loadItems(ofType type: String) {
        guard let itemType = ItemType(rawValue: type) else {
            fatalError("Incorrect ItemType \(type)")
        }
        
        // Here I use "map" function to transform array of OfflineItems to array of Items.
        
        items = offlineItems(of: itemType).map {
            return Item(offlineItem: $0)
        }
    }
    
    func item(ofType type: String, withTrackId trackId: Int) -> Item? {
        guard let itemType = ItemType(rawValue: type) else {
            fatalError("Incorrect ItemType \(type)")
        }
        
        if let offlineItem = offlineItem(of: itemType, with: trackId) {
            return Item(offlineItem: offlineItem)
        } else {
            return nil
        }
    }

    func deleteItem(_ item: Item) {
        if let existingItem = offlineItem(of: item.type, with: item.trackId) {
            deleteOfflineItem(existingItem)
        }
    }
}
