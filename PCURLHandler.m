//
// Created by Kyle Newsome on 2013-10-01.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PCURLHandler.h"
#import "PCStateManager.h"
#import "PCViewController.h"
#import "NetworkSetupViewController.h"
#import "NSString+URLEncode.h"


@implementation PCURLHandler

+ (PCURLHandler *)sharedInstance {
    static PCURLHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PCURLHandler alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation{
    if([url.scheme isEqualToString:@"postcard"]){
        NSString *controller = url.host;
        NSString *query = url.query;
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        for (NSString *param in [query componentsSeparatedByString:@"&"]) {
            NSArray *elements = [param componentsSeparatedByString:@"="];
            if([elements count] < 2) continue;
            [parameters setObject:[[elements objectAtIndex:1] urldecode] forKey:[elements objectAtIndex:0]];
        }
        self.parameters = parameters;

        PCStateManager *stateManager = [PCStateManager sharedInstance];
        if ([controller isEqualToString:@"setup"]){
            if(stateManager.networkSetupVC == nil){
                [stateManager.postcardVC performSegueWithIdentifier:@"pushNetworkSetup" sender:self];
            } else {
                [stateManager.networkSetupVC setupWithLoadParameters:_parameters];
            }
        }

        return YES;
    }
    return NO;
}

@end