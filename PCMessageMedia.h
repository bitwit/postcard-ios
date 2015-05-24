//
// Created by Kyle Newsome on 2013-10-05.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "PCMessageAttachment.h"


@interface PCMessageMedia : PCMessageAttachment

@property(nonatomic, strong) NSString *mimeType;

@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) NSData *imageData;

@property(nonatomic, strong) NSString *video; //name or URL of the video .mp4 file depending on whether the library was used
@property(nonatomic, strong) NSData *videoData;


//@property(nonatomic) BOOL didUseAssetFromLibrary;
//@property(nonatomic) CGSize videoDimensions;

-(void)setupWithContentUrl:(NSURL *)contentUrl;

-(NSUInteger)length;

@end