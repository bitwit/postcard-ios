//
// Created by Kyle Newsome on 2013-10-02.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "PCMessageAttachment.h"


@interface PCMessageLink : PCMessageAttachment <NSXMLParserDelegate>

@property(nonatomic, strong) NSString *url;
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *description;
@property(nonatomic, strong) NSString *imageURL;
@property(nonatomic, strong) UIImage *image;

- (void)setMessageLinkURL:(NSString *)url;
- (NSString *)originalUrl;

@end