//
// Created by Kyle Newsome on 1/8/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupURLButtonCell.h"


@implementation NetworkSetupURLButtonCell

-(IBAction)visitURL{
    if([self.delegate respondsToSelector:@selector(networkSetupCell:wantsToVisitURL:)]) {
        [self.delegate networkSetupCell:self wantsToVisitURL:_urlString];
    }
}

@end