//
// Created by Kyle Newsome on 2/27/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface PCEmbedMaker : NSObject

+(BOOL)canEmbedURL:(NSString *)urlString;
+(NSString *)embedCodeForURL:(NSString *)urlString;

@end