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
    
    func saveOrUpdateItem(_ item: Item) {
        if let existingItem = offlineItem(of: item.type, with: item.trackId) {
            existingItem.trackName = item.trackName
            existingItem.artistName = item.artistName

            print("Updated existing")
        } else {
            let newItem = OfflineItem(context: context)
            
            newItem.type = item.type.rawValue
            newItem.trackId = Int64(item.trackId)
            newItem.trackName = item.trackName
            newItem.artistName = item.artistName

            print("Saved new")
        }
        
        // I prefer to save Core Data context as soon as possible, for example for cases of unexpected app termination (like Stop command sent from Xcode).
        saveData()
    }
    
}
