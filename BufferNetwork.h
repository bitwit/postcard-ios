//
// Created by Kyle Newsome on 2013-09-16.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "Network.h"

@class OAuth2WebViewController;

@interface BufferNetwork : Network

-(void)webAuthViewSetup:(OAuth2WebViewController *)webAuthViewController;

- (void)requestProfilesWithCompletion:(void (^)(BOOL success, NSArray *profiles))handler;

- (NSArray *)getProfileIds;

@end