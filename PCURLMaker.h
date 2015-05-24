//
// Created by Kyle Newsome on 2013-10-07.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface PCURLMaker : NSObject

+(NSURL *)validURLForString:(NSString *)string withBaseURL:(NSString *)baseOrNil;
+(NSString *)validURLStringForString:(NSString *)string withBaseURL:(NSString *)baseOrNil;

@end