//
// Created by Kyle Newsome on 2013-09-16.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "BufferNetwork.h"
#import "PDKeychainBindings.h"
#import "PCSocialActivity.h"
#import "NetworkSetupViewController.h"
#import "OAuth2WebViewController.h"
#import "NSData+URLEncode.h"

#define ISO_TIMEZONE_UTC_FORMAT @"Z"
#define ISO_TIMEZONE_OFFSET_FORMAT @"%+02d%02d"

@interface BufferNetwork ()

@property(nonatomic, weak) PDKeychainBindings *keychain;
@property(nonatomic, strong) NSString *token;
@property(nonatomic, weak) OAuth2WebViewController *authViewController;
@property(nonatomic, strong) NSArray *profilesData;

//settings
@property(nonatomic, strong) NSArray *accountProfiles;
@property(nonatomic, strong) NSNumber *sendType;
@property(nonatomic, strong) NSDate *sendTime;
@end

@implementation BufferNetwork


- (id)init {
    self = [super init];
    if (self) {
        //set creation defaults
        self.sendType = @0;
        //standard init
        [self initializeBuffer];
    }
    return self;
}

- (void)initializeBuffer {
    self.name = @"buffer";
    self.tag = kBuffer;
    self.acceptsImages = YES;
    self.canHostContent = NO;
    self.keychain = [PDKeychainBindings sharedKeychainBindings];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"buffer_access_token"];
    NSString *accessToken = [self.keychain objectForKey:tokenName];
    if (accessToken) {
        self.token = accessToken;
        self.isLinked = YES;
    }
}

- (void)willDelete {
    [super willDelete];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"buffer_access_token"];
    [self.keychain removeObjectForKey:tokenName];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.accountProfiles = [aDecoder decodeObjectForKey:@"accountProfiles"];
        self.profilesData = [aDecoder decodeObjectForKey:@"profilesData"];
        self.sendType = [aDecoder decodeObjectForKey:@"sendType"];
        self.sendTime = [aDecoder decodeObjectForKey:@"sendTime"];
        BWLog(@"Buffer profiles %@ data %@ sendType %@ sendTime %@", _accountProfiles, _profilesData, _sendType, _sendTime);
        [self initializeBuffer];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_accountProfiles forKey:@"accountProfiles"];
    [coder encodeObject:_profilesData forKey:@"profilesData"];
    [coder encodeObject:_sendType forKey:@"sendType"];
    [coder encodeObject:_sendTime forKey:@"sendTime"];
    BWLog(@"Saving Buffer profiles %@ data %@ sendType %@ sendTime %@", _accountProfiles, _profilesData, _sendType, _sendTime);
}

- (NSArray *)settingFields {

    NSMutableArray *profileNames = [NSMutableArray array];
    for (NSDictionary *profile in _profilesData) {
        NSString *title = [NSString stringWithFormat:@"%@ - %@", [profile valueForKey:@"formatted_username"], [[profile valueForKey:@"service"] capitalizedString]];
        [profileNames addObject:title];
    }

    return @[  //table
            @[ //section
                    @{ //field
                            @"type" : @"ListSelection",
                            @"title" : @"Account Profiles",
                            @"property" : @"accountProfiles",
                            @"dataSource" : profileNames,
                            @"owner" : @"instance"
                    }
            ], @[ //section
                    @{  //field
                            @"type" : @"SegmentedControl",
                            @"title" : @"Send",
                            @"property" : @"sendType",
                            @"dataSource" : @[
                            @"Immediately", @"Buffer", @"Schedule"
                    ],
                            @"relatedFields" : @[
                            @"sendTime"
                    ],
                            @"owner" : @"instance"
                    },
                    @{  //field
                            @"type" : @"DatePicker",
                            @"title" : @"Schedule Time",
                            @"property" : @"sendTime",
                            @"showConditions" : @{
                            @"sendType" : @2 // "Schedule"
                    },
                            @"owner" : @"instance"
                    }
            ]
    ];
}

#pragma mark - Network Setup & Settings

- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    [setupManager.networkSetupVC performSegueWithIdentifier:@"modalOAuth2WebView" sender:self];
}

- (void)webAuthViewSetup:(OAuth2WebViewController *)webAuthViewController {
    BWLog(@"");
    NSString *redirectUri = @"http://www.postcardsocial.net";
    NSString *tokenUrl = @"https://api.bufferapp.com/1/oauth2/"; //the url to request the token once getting a code
    NSString *tokenPath = @"token.json"; //the url to request the token once getting a code
    NSDictionary *tokenPostData = @{
            @"client_id" : BUFFER_CLIENT_ID,
            @"client_secret" : BUFFER_CLIENT_SECRET,
            @"redirect_uri" : redirectUri,
            @"grant_type" : @"authorization_code"
    };

    NSDictionary *params = @{
            @"auth_url" : [NSString stringWithFormat:@"https://bufferapp.com/oauth2/authorize?client_id=%@&response_type=code&redirect_uri=%@", BUFFER_CLIENT_ID, redirectUri],
            @"code_title" : @"code",
            @"base_token_url" : tokenUrl,
            @"token_path" : tokenPath,
            @"token_post_data" : tokenPostData,
            @"token_title" : @"access_token"
    };

    self.authViewController = webAuthViewController;
    [_authViewController setupAuthWithParameters:params viewController:self.setupManager.networkSetupVC completion:^(BOOL success, NSString *token) {
        if (success) {
            self.token = token;
            NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"buffer_access_token"];
            [self.keychain setObject:token forKey:tokenName];

            self.isLinked = YES;
            [self requestProfilesWithCompletion:^(BOOL profileSuccess, NSArray *profiles) {
                BWNetLog(@"profiles -> %@", profiles)
                self.profilesData = profiles;
                [self.setupManager network:self setupCompleted:YES properties:@{
                        @"title" : @"Buffer Network"
                }];
            }];
        } else {
            [self.setupManager network:self setupCompleted:NO properties:@{
                    @"message" : @"Cancelled setup"
            }];
        }
        [self.setupManager.networkSetupVC dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (NSArray *)getProfileIds {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:_accountProfiles.count];
    for (NSNumber *arrayIdx in _accountProfiles) {
        NSString *profileId = _profilesData[(NSUInteger) arrayIdx.integerValue][@"id"];
        [array addObject:profileId];
    }
    return array;
}

- (void)requestProfilesWithCompletion:(void (^)(BOOL success, NSArray *profiles))handler {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", @"https://api.bufferapp.com/1/profiles.json?access_token=", _token];
    NSURL *url = [NSURL URLWithString:urlString];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];

    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:@"" parameters:nil];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"Operation Succeeded  --> %@", responseObject);
        handler(YES, responseObject);
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        handler(NO, nil);
    }];
    [httpClient enqueueHTTPRequestOperation:operation];
}

#pragma mark - Posting/Getting data

- (void)postUpdate:(PCSocialActivity *)activity {
    [super postUpdate:activity];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", @"https://api.bufferapp.com/1/updates/create.json?access_token=", _token]];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
            @"text" : activity.message,
            @"profile_ids" : self.getProfileIds,
    }];

    switch (_sendType.integerValue) {
        case 0: //send now
            parameters[@"now"] = @"true";
            break;
        case 2: //scheduled
        {
            NSDateFormatter *sISO8601 = [[NSDateFormatter alloc] init];

            NSTimeZone *timeZone = [NSTimeZone localTimeZone];
            int offset = [timeZone secondsFromGMT];

            NSMutableString *strFormat = [NSMutableString stringWithString:@"yyyyMMdd'T'HH:mm:ss"];
            offset /= 60; //bring down to minutes
            if (offset == 0)
                [strFormat appendString:ISO_TIMEZONE_UTC_FORMAT];
            else
                [strFormat appendFormat:ISO_TIMEZONE_OFFSET_FORMAT, offset / 60, offset % 60];

            [sISO8601 setTimeStyle:NSDateFormatterFullStyle];
            [sISO8601 setDateFormat:strFormat];

            parameters[@"scheduled_at"] = [sISO8601 stringFromDate:_sendTime];
        }
        default: //this will just buffer the post
            break;
    }

    NSMutableURLRequest *request;
    if (activity.messageLink) {
        parameters[@"text"] = activity.messageWithLink;
        parameters[@"media[link]"] = activity.messageLink.url;
    } else if (activity.messageMedia.imageData) {
        NSString *filename = [NSString stringWithFormat:@"%@.jpg", activity.date];
        request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"" parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            [formData appendPartWithFileData:activity.messageMedia.imageData name:@"media[picture]" fileName:filename mimeType:@"image/jpeg"];
        }];
    }

    if (request == nil) {
        request = [httpClient requestWithMethod:@"POST" path:@"" parameters:parameters];
    }

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"Operation Succeeded --> %@", responseObject);
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:nil ];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:failure];
        [Flurry logEvent:@"Buffer Post Error" withParameters:@{
                @"response" : op.responseString,
                @"wasHandled" : @(NO)
        }];
    }];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9; //leave 10% of completion for actual response
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];

    BWLog(@"%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);

    [httpClient enqueueHTTPRequestOperation:operation];

}


@end