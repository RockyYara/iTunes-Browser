//
//  OnlineDataManager.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

class OnlineDataManager {
    
    static let sharedInstance = OnlineDataManager()
    
    private let apiHelper = APIHelper()
    private let modelParser = ModelParser()
    
    private(set) var items = [Item]()

    func refreshItems(ofType type: ItemType, withSearchString searchString: String, completionHandler: @escaping (Bool) -> Void) {
        apiHelper.searchItems(ofType: type.rawValue, withSearchString: searchString) { [weak self] resultDict in
            guard let dict = resultDict else {
                completionHandler(false)
                return
            }
            
            guard let resultsArray = dict["results"] as? [Any] else {
                completionHandler(false)
                return
            }
            
            if let strongSelf = self {
                strongSelf.items = strongSelf.modelParser.parseArrayOfItemsFromJson(jsonArray: resultsArray)
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
}
