//
//  String+PercentEncoding.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/5/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation

extension String {
    
    func percentEncoded() -> String? {
        var result = addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
        
        // Additional characters encoding.
        result = result?.replacingOccurrences(of: "&", with: "%26").replacingOccurrences(of: "+", with: "%2B")
        
        return result
    }
    
}
