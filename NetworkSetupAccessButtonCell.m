//
// Created by Kyle Newsome on 2013-09-03.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NetworkSetupCell.h"
#import "NetworkSetupAccessButtonCell.h"


@implementation NetworkSetupAccessButtonCell
- (IBAction)setupButtonPressed {
    if([self.delegate respondsToSelector:@selector(networkSetupCellInitiatedSetup:)]){
        [self.delegate networkSetupCellInitiatedSetup:self];
    }
}


@end