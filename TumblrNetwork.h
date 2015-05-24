//
// Created by Kyle Newsome on 2013-10-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "Network.h"

@class OAuth1WebViewController;

@interface TumblrNetwork : Network

- (void)webAuthViewSetup:(OAuth1WebViewController *)webAuthViewController;

- (NSMutableURLRequest *)preparedRequestForPath:(NSString *)path parameters:(NSDictionary *)queryParameters HTTPmethod:(NSString *)HTTPmethod;
@end