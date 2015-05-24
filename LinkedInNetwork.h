//
// Created by Kyle Newsome on 2013-08-31.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Network.h"

@class OAuth2WebViewController;

@interface LinkedInNetwork : Network

- (void)webAuthViewSetup:(OAuth2WebViewController *)webAuthViewController;

@end