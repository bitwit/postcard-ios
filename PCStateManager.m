//
// Created by Kyle Newsome on 2013-10-01.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PCStateManager.h"
#import "NetworkSetupViewController.h"
#import "PCViewController.h"


@implementation PCStateManager

+ (PCStateManager *)sharedInstance {
    static PCStateManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PCStateManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end