//
// Created by Kyle Newsome on 11/26/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupMessageCell.h"


@implementation NetworkSetupMessageCell

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
    bgView.backgroundColor = [PCColorPalette lightOrangeColor];
    self.selectedBackgroundView = bgView;
    return self;
}

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value{
    self.messageLabel.text = value;
    [self.messageLabel updateConstraints];
}

-(id)getValue{
    return self.messageLabel.text;
}


@end