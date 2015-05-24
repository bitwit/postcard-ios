//
//  Postcard.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-06-11.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "Postcard.h"


@implementation Postcard

@dynamic date;
@dynamic message;
@dynamic link;
@dynamic tags;
@dynamic image;
@dynamic video;
@dynamic mediaMimeType;
@dynamic networkPosts;

-(void)prepareForDeletion {
    //TODO: delete image and/or video content from documents directory
}

@end
