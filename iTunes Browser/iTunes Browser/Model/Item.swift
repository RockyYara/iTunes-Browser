//
//  Item.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

class Item {
    
    let trackId: Int
    let trackName: String
    let artistName: String
    
    let artworkUrl60: String?
    
    init(trackId: Int, trackName: String, artistName: String, artworkUrl60: String?) {
        self.trackId = trackId
        self.trackName = trackName
        self.artistName = artistName
        self.artworkUrl60 = artworkUrl60
    }
    
}