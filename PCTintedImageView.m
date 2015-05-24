//
// Created by Kyle Newsome on 1/22/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "PCTintedImageView.h"


@implementation PCTintedImageView

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.image = [self.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return self;
}

@end