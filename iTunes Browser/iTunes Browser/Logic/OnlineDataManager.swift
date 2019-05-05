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
    
    private init() {
        // Temporarily for test purposes.
        test_fillItemsArrayWithTestData()
    }
    
    func refreshMusicItems(withSearchString searchString: String, completionHandler: @escaping (Bool) -> Void) {
        apiHelper.searchItems(ofType: "music", withSearchString: searchString) { [weak self] resultDict in
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
    
    // Temporarily for test purposes.
    private func test_fillItemsArrayWithTestData() {
        for i in 1...5 {
            items.append(Item.init(trackId: i, trackName: "Track \(i)", artistName: "Artist \(i)", artworkUrl60: nil))
        }
    }
    
}
