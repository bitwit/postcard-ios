//
// Created by Kyle Newsome on 2013-10-07.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PCURLMaker.h"


@implementation PCURLMaker

+ (NSURL *)validURLForString:(NSString *)string withBaseURL:(NSString *)baseOrNil {
    NSMutableString *fixedURLString = [NSMutableString string];
    if([[string substringToIndex:1] isEqualToString:@"/"]){
        if(baseOrNil != nil){
            [fixedURLString appendString:baseOrNil];
            [fixedURLString appendString:string];
        } else {
            return nil; //we can't do anything with this URL
        }
    } else {
        [fixedURLString appendString:string];
    }

    NSURL *url = [NSURL URLWithString:fixedURLString];
    BWLog(@"URL -- %@ \n\n AbsoluteString: %@ \n Scheme: %@ \n Host: %@ \n Component: %@ \n Query: %@", string, url.absoluteString, url.scheme, url.host, url.pathComponents, url.query);

    if(url.scheme == nil && url.host == nil && baseOrNil != nil){
        [fixedURLString setString:@""];
        [fixedURLString appendString:baseOrNil];
        [fixedURLString appendString:@"/"]; //if this had existed previously, it would have been caught at the start
        [fixedURLString appendString:string];
        url = [NSURL URLWithString:fixedURLString];
    }

    if(url.scheme == nil){
        [fixedURLString setString:@""];
        [fixedURLString appendString:@"http://"];
        [fixedURLString appendString:url.absoluteString];
        url = [NSURL URLWithString:fixedURLString];
    }

    if(url.scheme == nil || url.host == nil){
        return nil; //we can't fix this url, the host or scheme is very unclear. there may be too many slashes after the "http://"
    }
    return url;
}

+ (NSString *)validURLStringForString:(NSString *)string withBaseURL:(NSString *)baseOrNil {
    return [PCURLMaker validURLForString:string withBaseURL:baseOrNil].absoluteString;
}

@end