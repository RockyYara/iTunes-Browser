//
//  UIImage+Grayscaling.swift
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/27/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func grayscaled() -> UIImage? {
        guard let inputImage = CIImage(image: self), let filter = CIFilter(name: "CIPhotoEffectTonal") else { return nil }
        
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
}
