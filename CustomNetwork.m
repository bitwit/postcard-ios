//
// Created by Kyle Newsome on 2013-07-20.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "CustomNetwork.h"
#import "PDKeychainBindings.h"
#import "PCURLMaker.h"

@interface CustomNetwork ()
@property(nonatomic, weak) PDKeychainBindings *keychain;
@property(nonatomic, strong) NSString *token;

//settings
@property(nonatomic, strong) NSNumber *shouldRemoveLink;

//for setup
@property(nonatomic, strong) NSString *placeholderTitle;

@end

@implementation CustomNetwork

- (id)init {
    self = [super init];
    if (self) {
        //set creation defaults
        self.shouldRemoveLink = @YES;
        //and standard initialization
        [self initializeCustomNetwork];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.siteUrl = [aDecoder decodeObjectForKey:@"siteUrl"];
    [self setShouldRemoveLink:[aDecoder decodeObjectForKey:@"shouldRemoveLink"]];
    [self initializeCustomNetwork];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.siteUrl forKey:@"siteUrl"];
    [coder encodeObject:self.shouldRemoveLink forKey:@"shouldRemoveLink"];
}

- (void)initializeCustomNetwork {
    self.keychain = [PDKeychainBindings sharedKeychainBindings];
    self.name = @"custom";
    self.tag = kCustom;
    self.usesTags = YES;
    self.acceptsImages = YES;
    self.acceptsVideo = YES;
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"custom_access_token"];
    NSString *accessToken = [self.keychain objectForKey:tokenName];
    if (accessToken) {
        self.token = accessToken;
        self.isLinked = YES;
    }

    if(self.shouldRemoveLink == nil){ //upgrading users need a default setting of YES
        self.shouldRemoveLink = @YES;
    }
}

- (void)willDelete {
    [super willDelete];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"custom_access_token"];
    [self.keychain removeObjectForKey:tokenName];
}

- (NSArray *)settingFields {
    return @[  //table
            @[
                    @{  //field
                            @"type" : @"SegmentedControl",
                            @"title" : @"Remove link from message?",
                            @"property" : @"shouldRemoveLink",
                            @"dataSource" : @[
                            @"No", @"Yes"
                    ],
                            @"owner" : @"instance"
                    }
            ]
    ];
}

- (void)loginWithCredentials:(NSString *)user password:(NSString *)pass {
    NSString *body = @"username=%@&password=%@";
    body = [NSString stringWithFormat:body, user, pass];

    NSString *urlString = [NSString stringWithFormat:@"%@authenticate", self.siteUrl];
    NSURL *url = [[NSURL alloc] initWithString:urlString];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setTimeoutInterval:15.0f];
    [urlRequest setHTTPBody:[body dataUsingEncoding:NSISOLatin1StringEncoding]];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:urlRequest success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        BWLog(@"Response -> %@", JSON);
        self.token = [JSON valueForKeyPath:@"payload.token"];
        BWLog(@"new token -> %@", self.token);
        self.isLinked = YES;

        self.UUID = [[NSUUID UUID] UUIDString];
        NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"custom_access_token"];
        [self.keychain setObject:_token forKey:tokenName];

        [self.setupManager network:self setupCompleted:YES properties:@{
                @"title" : (_placeholderTitle != nil) ? _placeholderTitle : [NSString stringWithFormat:@"%@ @ %@", user, _siteUrl]
        }];
    }                                                                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        BWLog(@"Error %@", [error description]);
        NSString *errorMessage = (JSON[@"message"] != nil && JSON[@"message"] != [NSNull null]) ? JSON[@"message"] : @"General error connecting network";
        [self.setupManager network:self setupCompleted:NO properties:@{
                @"message" : errorMessage
        }];
    }];
    operation.allowsInvalidSSLCertificate = YES;
    [operation start];
}

#pragma mark - Network

-(void)confirmNetworkSiteURLAndLogin{
    NSURL *url = [[NSURL alloc] initWithString:self.siteUrl];

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest setTimeoutInterval:15.0f];

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:urlRequest];
    operation.allowsInvalidSSLCertificate = YES;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"This url works");
        @try{
            NSString *title = [responseObject valueForKeyPath:@"payload.title"];
            self.placeholderTitle = ([title isKindOfClass:[NSString class]]) ? title : nil;
        }
        @catch(NSException *e) {
            [Flurry logEvent:@"Custom Network Title Grab Error" withParameters:@{
                    @"response":  op.responseString,
                    @"wasHandled": @(NO)
            }];
            self.placeholderTitle = nil;
        }
        [self loginWithCredentials:_username password:_password];
    } failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"This url doesnt work");
        BWLog(@"Custom Network Setup Error - %@", failure);
        if([_siteUrl rangeOfString:@"postcard_api=true"].location == NSNotFound){
            self.siteUrl = [NSString stringWithFormat:@"%@?postcard_api=true&endpoint=", url.absoluteString];
            [self confirmNetworkSiteURLAndLogin];
        }else {
            [self.setupManager network:self setupCompleted:NO properties:@{
                    @"message" : @"The custom network url you have provided doesn't appear to be responding correctly to Postcard"
            }];
        }
    }];
    [operation start];
}

- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    NSString *originalURL = _siteUrl;
    @try{
        NSURL *url = [PCURLMaker validURLForString:_siteUrl withBaseURL:nil];
        BWLog(@"Initial url scan -> %@ scheme %@ host %@ path %@", url, url.scheme, url.host, url.path);
        NSURL *querylessURL = [[NSURL alloc] initWithScheme:url.scheme
                                                       host:url.host
                                                       path:([url.path isEqualToString:@""] || url.path == nil) ? @"/" : [NSString stringWithFormat:@"%@/", url.path]];
        BWLog(@"queryless url scan -> %@", querylessURL);
        self.siteUrl = querylessURL.absoluteString;

        [self confirmNetworkSiteURLAndLogin];

    }
    @catch(NSException *e){
        BWLog(@"URL parsing error - %@", originalURL);
        [Flurry logEvent:@"Invalid custom URL" withParameters:@{
                @"siteUrl": originalURL
        }];
        [self.setupManager network:self setupCompleted:NO properties:@{
                @"message" : @"The custom network url you have provided appears to be invalid. Please double check it and contact me if you believe this is an error."
        }];
    }
}

- (void)postUpdate:(PCSocialActivity *)activity {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
            @"token" : _token,
            @"message" : (_shouldRemoveLink.boolValue) ? activity.message : activity.messageWithLink,
            @"date" : activity.date
    }];

    if (activity.tags) {
        parameters[@"tags"] = activity.tags;
    }

    NSMutableURLRequest *request;
    if (activity.messageMedia.videoData) {
        NSData *imageData = UIImageJPEGRepresentation(activity.messageMedia.image, 0.7);
        NSString *imageFilename = [NSString stringWithFormat:@"%@.jpg", activity.date];
        NSString *videoFilename = [NSString stringWithFormat:@"%@.mp4", activity.date];

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_siteUrl,@"post/add_with_media"]];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        request = [httpClient multipartFormRequestWithMethod:@"POST" path:nil parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"image" fileName:imageFilename mimeType:@"image/jpeg"];
            [formData appendPartWithFileData:activity.messageMedia.videoData name:@"video" fileName:videoFilename mimeType:@"video/mp4"];
        }];

    } else if (activity.messageMedia.imageData) {
        NSString *filename = [NSString stringWithFormat:@"%@.jpg", activity.date];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_siteUrl,@"post/add_with_media"]];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        request = [httpClient multipartFormRequestWithMethod:@"POST" path:nil parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:activity.messageMedia.imageData name:@"image" fileName:filename mimeType:@"image/jpeg"];
        }];
    }
    else {
        if (activity.messageLink) {
            [parameters setObject:activity.messageLink.url forKey:@"url"];
        }
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",_siteUrl, @"post/add"]];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        request = [httpClient requestWithMethod:@"POST" path:nil parameters:parameters];
    }

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    operation.allowsInvalidSSLCertificate = YES;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"Operation Succeeded --> %@", responseObject);
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                @"id": [[responseObject valueForKeyPath:@"payload.id"] stringValue],
                @"permalink": [responseObject valueForKeyPath:@"payload.permalink"]
        }];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:failure];
        [Flurry logEvent:@"Custom Network Post Error" withParameters:@{
                @"response":  op.responseString,
                @"wasHandled": @(NO)
        }];
    }];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWNetLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9;
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];

    [operation start];
}

@end
