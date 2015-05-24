//
// Created by Kyle Newsome on 1/12/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "PCTutorialManager.h"
#import "UIImage+animatedGIF.h"
#import "UIView+SDCAutoLayout.h"

@implementation PCTutorialManager

+ (BOOL)hasWatchedMainViewTutorial {
   return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasWatchedMainViewTutorial"];
}

+ (BOOL)hasWatchedNetworkSetupTutorial {
   return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasWatchedNetworkSetupTutorial"];
}

+ (BOOL)hasWatchedNetworkSettingsTutorial {
   return [[NSUserDefaults standardUserDefaults] boolForKey:@"hasWatchedNetworkSettingsTutorial"];
}

+(void)setMainViewTutorialAsWatched{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:YES forKey:@"hasWatchedMainViewTutorial"];
    [settings synchronize];
}

+(void)setNetworkSetupTutorialAsWatched{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:YES forKey:@"hasWatchedNetworkSetupTutorial"];
    [settings synchronize];
}

+(void)setNetworkSettingsTutorialAsWatched {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:YES forKey:@"hasWatchedNetworkSettingsTutorial"];
    [settings synchronize];
}

+ (void)resetTutorial {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool:NO forKey:@"hasWatchedMainViewTutorial"];
    [settings setBool:NO forKey:@"hasWatchedNetworkSetupTutorial"];
    [settings setBool:NO forKey:@"hasWatchedNetworkSettingsTutorial"];
    [settings synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TutorialDidReset" object:nil];
}


@end