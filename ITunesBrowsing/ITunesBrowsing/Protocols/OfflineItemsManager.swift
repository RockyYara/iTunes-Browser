//
//  OfflineItemsManager.swift
//  ITunesBrowsing
//
//  Created by Yaroslav Sverdlikov on 6/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

@objc protocol OfflineItemsManager {
    var items: [Item] { get }
    
    func loadItems(ofType type: String)
    // This method should load items of a specified type from a storage and make them ready to be accessed in items property
    // of the protocol conforming object.

    func item(ofType type: String, withTrackId trackId: Int) -> Item?

    func saveOrUpdateItem(_ item: Item)
    func deleteItem(_ item: Item)
}
