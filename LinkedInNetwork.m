//
// Created by Kyle Newsome on 2013-08-31.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "LinkedInNetwork.h"
#import "PDKeychainBindings.h"
#import "OAuth2WebViewController.h"
#import "NetworkSetupViewController.h"

@interface LinkedInNetwork ()
@property(nonatomic, weak) PDKeychainBindings *keychain;
@property(nonatomic, strong) NSString *token;
@property(nonatomic, weak) OAuth2WebViewController *authViewController;
@end

@implementation LinkedInNetwork

- (id)init {
    self = [super init];
    if (self) {
        [self initializeLinkedIn];
    }
    return self;
}

- (void)initializeLinkedIn {
    self.name = @"linkedin";
    self.tag = kLinkedIn;
    self.keychain = [PDKeychainBindings sharedKeychainBindings];
    self.canHostContent = NO;
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"linkedin_access_token"];
    NSString *accessToken = [self.keychain objectForKey:tokenName];
    if (accessToken) {
        self.token = accessToken;
        self.isLinked = YES;
    }
}

- (void)willDelete {
    [super willDelete];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"linkedin_access_token"];
    [self.keychain removeObjectForKey:tokenName];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeLinkedIn];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
}

#pragma mark - Network

- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    [setupManager.networkSetupVC performSegueWithIdentifier:@"modalOAuth2WebView" sender:self];
}

- (NSString *)generateState {
    static NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:16];
    for (int i = 0; i < 16; i++) {
        [randomString appendFormat:@"%C", [letters characterAtIndex:arc4random() % [letters length]]];
    }
    return randomString;
}

- (void)webAuthViewSetup:(OAuth2WebViewController *)webAuthViewController {
    NSString *state = [self generateState];
    NSString *redirectUri = @"http://www.postcardsocial.net";
    NSString *tokenUrl = @"https://www.linkedin.com/uas/oauth2/"; //the url to request the token once getting a code
    NSString *tokenPath = @"accessToken"; //the url to request the token once getting a code
    NSArray *accessType = @[@"r_fullprofile", @"r_network", @"rw_nus"];
    NSDictionary *tokenPostData = @{
            @"client_id" : LINKEDIN_CLIENT_ID,
            @"client_secret" : LINKEDIN_CLIENT_SECRET,
            @"redirect_uri" : redirectUri,
            @"grant_type" : @"authorization_code"
    };

    NSDictionary *params = @{
            @"auth_url" : [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&client_id=%@&scope=%@&state=%@&redirect_uri=%@", LINKEDIN_CLIENT_ID, [accessType componentsJoinedByString:@"%20"], state, redirectUri],
            @"code_title" : @"code",
            @"base_token_url" : tokenUrl,
            @"token_path" : tokenPath,
            @"token_post_data" : tokenPostData,
            @"token_title" : @"access_token",
            @"state" : state
    };

    self.authViewController = webAuthViewController;
    [_authViewController setupAuthWithParameters:params viewController:self.setupManager.networkSetupVC completion:^(BOOL success, NSString *token) {
        if (success) {
            NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"linkedin_access_token"];
            [self.keychain setObject:token forKey:tokenName];
            self.token = token;
            self.isLinked = YES;
            [self requestProfileWithCompletion:^(BOOL profileSuccess, NSDictionary *profile) {
                if (profileSuccess) {
                    NSString *name = [NSString stringWithFormat:@"%@ %@", profile[@"firstName"], profile[@"lastName"]];
                    [self.setupManager network:self setupCompleted:YES properties:@{
                            @"title" : name
                    }];
                } else {
                    BWLog(@"Setup error grabbing profile");
                    [self.setupManager network:self setupCompleted:NO properties:nil];
                }
            }];
        } else {
            BWLog(@"Setup error getting access token after auth");
            [self.setupManager network:self setupCompleted:NO properties:@{@"message": @"Cancelled setup"}];
        }
        [self.setupManager.networkSetupVC dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)requestProfileWithCompletion:(void (^)(BOOL success, NSDictionary *profile))handler {
    NSString *urlString = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~?oauth2_access_token=%@&format=json", _token];
    NSURL *url = [NSURL URLWithString:urlString];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];

    NSMutableURLRequest *request = [httpClient requestWithMethod:@"GET" path:@"" parameters:nil];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"Operation Succeeded  --> %@", responseObject);
        handler(YES, responseObject);
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Operation failed -- %@", [op responseString]);
        handler(NO, nil);
    }];
    [httpClient enqueueHTTPRequestOperation:operation];
}

- (NSString *)xmlForDictionary:(NSDictionary *)dict {
    //Only dictionaries and strings work with this function. LinkedIn has no array or number based inputs
    NSMutableString *xml = [NSMutableString string];
    for (NSString *key in dict.allKeys) {
        id value = dict[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            [xml appendString:[NSString stringWithFormat:@"<%@>%@</%@>", key, [self xmlForDictionary:value], key]];
        } else if ([value isKindOfClass:[NSString class]]) {
            [xml appendString:[NSString stringWithFormat:@"<%@>%@</%@>", key, value, key]];
        }
    }
    return xml;
}

- (void)postUpdate:(PCSocialActivity *)activity {
    [super postUpdate:activity];

    NSURL *url = [NSURL URLWithString:@"https://api.linkedin.com/v1/people/~/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/xml"];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
            @"comment" : activity.message,
            @"visibility" : @{
                    @"code" : @"anyone"
            }
    }];

    if (activity.messageLink != nil) {
        NSMutableDictionary *attachment = [NSMutableDictionary dictionaryWithDictionary:@{
                @"title" : activity.messageLink.title,
                @"description" : activity.messageLink.description,
                @"submitted-url" : activity.messageLink.url
        }];
        if (activity.messageLink.imageURL) {
            [attachment setValue:activity.messageLink.imageURL forKeyPath:@"submitted-image-url"];
        }
        [parameters setValue:attachment forKeyPath:@"content"];
    }

    NSMutableString *xmlBody = [NSMutableString stringWithString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [xmlBody appendString:[self xmlForDictionary:@{@"share" : parameters}]];
    //NSString *xmlBody = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><share><comment>%@</comment><visibility><code>anyone</code></visibility></share>", activity.message];

    NSString *path = [NSString stringWithFormat:@"shares?oauth2_access_token=%@", _token];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:nil];

    //NSString *error;
    //NSData *xml = [NSPropertyListSerialization dataFromPropertyList:parameters format:NSPropertyListFor errorDescription:&error];
    //BWLog(@"xml -> %@", [[NSString alloc] initWithData:xml encoding:NSUTF8StringEncoding]);

    BWNetLog(@"%@", xmlBody);
    request.HTTPBody = [xmlBody dataUsingEncoding:NSUTF8StringEncoding];

    AFXMLRequestOperation *operation = [[AFXMLRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"Operation Succeeded --> %@", responseObject);
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:nil ];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:[NSError errorWithDomain:[op responseString] code:400 userInfo:nil]];
        [Flurry logEvent:@"LinkedIn Post Error" withParameters:@{
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

    [httpClient enqueueHTTPRequestOperation:operation];
}

@end