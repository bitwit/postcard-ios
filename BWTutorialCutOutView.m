//
// Created by Kyle Newsome on 1/21/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "BWTutorialCutOutView.h"

@implementation BWTutorialCutOutView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 1.0f;
    return self;
}

@end