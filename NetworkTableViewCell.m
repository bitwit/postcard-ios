//
//  PostcardTableViewCell.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-06-11.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "NetworkTableViewCell.h"

@implementation NetworkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
