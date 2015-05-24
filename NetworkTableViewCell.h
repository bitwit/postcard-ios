//
//  PostcardTableViewCell.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-06-11.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetworkTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *mainImage;
@property (nonatomic, strong) IBOutlet UILabel *networkName;

@end
