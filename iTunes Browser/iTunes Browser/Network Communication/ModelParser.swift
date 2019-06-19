//
//  ModelParser.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import ITunesBrowsing

class ModelParser {
    
    // The caller supplies ModelParser with the information about type of items to parse because it definitely knows the type of items to parse.

    func parseArrayOfItems(of type: ItemType, from jsonArray: [Any]) -> [Item] {
        var arrayOfItems = [Item]()
        
        if let itemsJsonArray = jsonArray as? [[String : Any]] {
            for itemJsonDictionary in itemsJsonArray {
                if let item = parseItem(of: type, from: itemJsonDictionary) {
                    arrayOfItems.append(item)
                }
            }
        }
        
        return arrayOfItems
    }
    
    private func parseItem(of type: ItemType, from jsonDict: [String : Any]) -> Item? {
        if let trackId = jsonDict["trackId"] as? Int, let trackName = jsonDict["trackName"] as? String, let artistName = jsonDict["artistName"] as? String {
            let artworkUrl60 = jsonDict["artworkUrl60"] as? String
            
            return Item(type: type, trackId: trackId, trackName: trackName, artistName: artistName, artworkUrl60: artworkUrl60)
        } else {
            return nil
        }
    }
    
}
