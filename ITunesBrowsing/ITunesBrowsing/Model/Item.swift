//
//  Item.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

public class Item: NSObject {
    
    let type: ItemType
    
    let trackId: Int
    let trackName: String
    let artistName: String
    
    let artworkUrl60: String?
    
    var image: UIImage?
    var imageDownloadStatus = DownloadStatus.notStarted
    // At the beginning every item will start without downloaded image. It will be downloaded on demand.
    
    init(type: ItemType, trackId: Int, trackName: String, artistName: String, artworkUrl60: String?) {
        self.type = type
        self.trackId = trackId
        self.trackName = trackName
        self.artistName = artistName
        self.artworkUrl60 = artworkUrl60
    }
    
}
