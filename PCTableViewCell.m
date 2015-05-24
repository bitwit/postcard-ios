//
// Created by Kyle Newsome on 2013-09-23.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCTableViewCell.h"


@implementation PCTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
        bgView.backgroundColor = [PCColorPalette lightOrangeColor];
        self.selectedBackgroundView = bgView;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
    bgView.backgroundColor = [PCColorPalette lightOrangeColor];
    self.selectedBackgroundView = bgView;
    return self;
}

@end