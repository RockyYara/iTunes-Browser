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

    func refreshItems(of type: ItemType, with searchString: String, completionHandler: @escaping (Bool) -> Void) {
        apiHelper.searchItems(of: type.rawValue, with: searchString) { [weak self] resultDict in
            guard let dict = resultDict else {
                completionHandler(false)
                return
            }
            
            guard let resultsArray = dict["results"] as? [Any] else {
                completionHandler(false)
                return
            }
            
            if let strongSelf = self {
                strongSelf.items = strongSelf.modelParser.parseArrayOfItems(of: type, from: resultsArray)
                // Here we supply ModelParser with the information about type of items because we definitely know the type of items we are currently requesting.
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
    
    func downloadImage(for item: Item, completionHandler: @escaping (Bool) -> Void) {
        guard let url = item.artworkUrl60 else {
            completionHandler(false)
            return
        }
        
        apiHelper.externalResourceGetData(with: url) { resultData in
            guard let data = resultData else {
                completionHandler(false)
                return
            }
            
            if let image = UIImage(data: data) {
                item.image = image
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        }
    }
}
