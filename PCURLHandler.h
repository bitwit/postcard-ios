//
// Created by Kyle Newsome on 2013-10-01.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface PCURLHandler : NSObject

@property(nonatomic, strong) NSDictionary *parameters;

+ (PCURLHandler *)sharedInstance;

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
  sourceApplication:(NSString *)source annotation:(id)annotation;


@end