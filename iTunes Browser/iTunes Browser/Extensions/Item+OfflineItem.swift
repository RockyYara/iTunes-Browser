//
//  Item+OfflineItem.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 6/18/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import ITunesBrowsing

extension Item {
    convenience init(offlineItem: OfflineItem) {
        guard let type = offlineItem.type, let itemType = ItemType(rawValue: type),
            let trackName = offlineItem.trackName, let artistName = offlineItem.artistName else {
                fatalError("Incorrect OfflineItem")
        }
        
        self.init(type: itemType, trackId: Int(offlineItem.trackId), trackName: trackName, artistName: artistName, artworkUrl60: nil)
        
        if let imageData = offlineItem.image {
            self.image = UIImage(data: imageData)
        }
    }
}
