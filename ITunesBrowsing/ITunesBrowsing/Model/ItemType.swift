//
//  ItemType.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/6/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

public enum ItemType: String, CaseIterable {
    
    // New media types can be easily added as new cases of ItemType enum.
    // This is the only required thing to be done to add new media types throughout the app.

    case music
    case ebook
    case software
    case podcast
    
    func defaultSearchString() -> String {
        switch self {
        case .music:
            return "It's my life"
        case .ebook:
            return "Fifty Shades of Grey"
        case .software:
            return "App Store Connect"
        default:
            return "Something interesting"
        }
    }
    
}
