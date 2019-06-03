//
//  OfflineDataManager.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/16/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import CoreData

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
    
    func offlineItem(of type: ItemType, with trackId: Int) -> OfflineItem? {
        let fetchRequest = NSFetchRequest<OfflineItem>(entityName: "OfflineItem")
        fetchRequest.predicate = NSPredicate(format: "type = %@ AND trackId = %@", argumentArray: [type.rawValue, trackId])
        
        if let results = try? context.fetch(fetchRequest) as [OfflineItem], results.count > 0 {
            return results[0]
        } else {
            return nil
        }
    }
    
    func loadItems(of type: ItemType) {
        // Here I use "map" function to transform array of OfflineItems to array of Items.
        
        items = offlineItems(of: type).map {
            let item = Item(type: type, trackId: Int($0.trackId), trackName: $0.trackName ?? "", artistName: $0.artistName ?? "", artworkUrl60: nil)
            
            if let imageData = $0.image {
                item.image = UIImage(data: imageData)
            }
            
            return item
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
    
    func deleteOfflineItem(_ offlineItem: OfflineItem) {
        context.delete(offlineItem)

        print("Deleted")

        // I prefer to save Core Data context as soon as possible, for example for cases of unexpected app termination (like Stop command sent from Xcode).
        saveData()
    }
    
}
