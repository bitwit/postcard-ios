//
// Created by Kyle Newsome on 2/27/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "PCEmbedMaker.h"
#import "PCURLMaker.h"
#import "NSString+URLEncode.h"

@interface PCEmbedMaker ()
@property(nonatomic, strong) NSString *documentsPath;
@property(nonatomic, strong) NSString *resourcesPath;
@end

@implementation PCEmbedMaker

+ (BOOL)canEmbedURL:(NSString *)urlString {
    NSURL *url = [PCURLMaker validURLForString:urlString withBaseURL:nil];
    NSArray *embeddableHosts = @[
            @"vimeo",
            @"youtube",
            @"youtu.be"
    ];
    for (NSString *host in embeddableHosts) {
        if ([url.host rangeOfString:host].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)embedCodeForURL:(NSString *)urlString {
    NSURL *url = [PCURLMaker validURLForString:urlString withBaseURL:nil];
    NSArray *embeddableHosts = @[
            @{@"host" : @"vimeo", @"template" : @"vimeo", @"component" : @1},
            @{@"host" : @"youtu.be", @"template" : @"youtube", @"component" : @1},
            @{@"host" : @"youtube", @"template" : @"youtube", @"query": @"v"}
    ];
    for (NSDictionary *host in embeddableHosts) {
        if ([url.host rangeOfString:host[@"host"]].location != NSNotFound) {
            NSString *id;
            if (host[@"component"] != nil) {
                id = url.pathComponents[[host[@"component"] intValue]]; // O:/, 1:video_id
            } else if(host[@"query"] != nil)   {
                NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                for (NSString *param in [url.query componentsSeparatedByString:@"&"]) {
                    NSArray *elements = [param componentsSeparatedByString:@"="];
                    if([elements count] < 2) continue;
                    [parameters setObject:[[elements objectAtIndex:1] urldecode] forKey:[elements objectAtIndex:0]];
                }
                id = parameters[host[@"query"]];
            }
            return [PCEmbedMaker buildEmbedWithTemplate:host[@"template"] embedID:id];
        }
    }
    return nil;
}

+ (NSString *)buildEmbedWithTemplate:(NSString *)templateName embedID:(NSString *)embedID {
    NSString *embed = [[PCEmbedMaker stringFromTemplate:templateName] stringByReplacingOccurrencesOfString:@"#{id}" withString:embedID];
    BWLog(@"Final embed code > %@", embed);
    return embed;
}

+ (NSString *)stringFromTemplate:(NSString *)templateName {
    BWLog(@"%@", templateName);
    NSString *filePath = [[NSBundle mainBundle] pathForResource:templateName ofType:@"html"];
    NSError *error;
    NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    BWLog(@"embed code > %@", content);
    return content;
}


@end