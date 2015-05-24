//
// Created by Kyle Newsome on 1/12/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface PCTutorialManager : NSObject

+ (BOOL)hasWatchedMainViewTutorial;
+ (BOOL)hasWatchedNetworkSetupTutorial;
+ (BOOL)hasWatchedNetworkSettingsTutorial;

+ (void)setMainViewTutorialAsWatched;
+ (void)setNetworkSetupTutorialAsWatched;
+ (void)setNetworkSettingsTutorialAsWatched;

+ (void)resetTutorial;

@end