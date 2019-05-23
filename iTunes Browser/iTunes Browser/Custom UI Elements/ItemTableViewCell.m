//
//  ItemTableViewCell.m
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/17/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

#import "ItemTableViewCell.h"

@implementation ItemTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.savedLocallyImageView setHidden:NO];
    self.savedLocallyImageView.alpha = 0;
    // I didn't do this in cell's xib because I want the cell to look in Xcode more similar to its runtime appearance.
    
    self.savedLocallyImageView.image = [ItemTableViewCell savedLocallyImage];
}

+ (UIImage *)savedLocallyImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        UIImage *templateImage = [UIImage imageNamed:@"checkmark"];
        image = [templateImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        // Here we create template image, this will allow it to be colored to tint color of UIImageView it will be displayed in.
        // This will be done only once, after that result will be stored in static var "image".
    });
    
    return image;
}

@end
