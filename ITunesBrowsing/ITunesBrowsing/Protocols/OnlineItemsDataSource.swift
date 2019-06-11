//
//  OnlineItemsDataSource.swift
//  ITunesBrowsing
//
//  Created by Yaroslav Sverdlikov on 6/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

@objc public protocol OnlineItemsDataSource {
    var items: [Item] { get }
    
    func refreshItems(ofType type: String, withSearchString searchString: String, completionHandler: @escaping (_ success: Bool) -> Void)
    // This method should refresh items using criterias supplied in its parameters and make items ready to be accessed in items property
    // of the data source object.
    
    func downloadImage(for item: Item, completionHandler: @escaping (_ success: Bool) -> Void)
}
