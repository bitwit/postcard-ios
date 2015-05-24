//
// Created by Kyle Newsome on 2013-10-01.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class PCViewController;
@class NetworkSetupViewController;

@interface PCStateManager : NSObject

@property(nonatomic, weak) PCViewController *postcardVC;
@property(nonatomic, weak) NetworkSetupViewController *networkSetupVC;

+ (PCStateManager *)sharedInstance;

@end