//
//  ItemTableViewCell.h
//  iTunes Browser
//
//  Created by Yaroslav Sverdlikov on 5/17/19.
//  Copyright © 2019 Yaroslav Sverdlikov. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ItemTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *itemNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *authorNameLabel;

@property (nonatomic, weak) IBOutlet UIImageView *itemImageView;
@property (nonatomic, weak) IBOutlet UIImageView *savedLocallyImageView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

NS_ASSUME_NONNULL_END
