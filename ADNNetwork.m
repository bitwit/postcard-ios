//
// Created by kylenewsome on 2012-12-22.
//


#import "ADNNetwork.h"
#import "PDKeychainBindings.h"
#import "NSData+URLEncode.h"

@interface ADNNetwork ()
@property(nonatomic, weak) PDKeychainBindings *keychain;
@property(nonatomic, strong) NSString *token;
@property(nonatomic, strong) PCSocialActivity *currentActivity;
@end

@implementation ADNNetwork

- (id)init {
    self = [super init];
    if (self) {
        [self initializeAdn];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self initializeAdn];
    return self;
}

- (void)initializeAdn {
    self.keychain = [PDKeychainBindings sharedKeychainBindings];
    self.name = @"adn";
    self.tag = kADN;
    self.charLimit = 256;
    self.acceptsImages = YES;
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"adn_access_token"];
    NSString *accessToken = [self.keychain objectForKey:tokenName];
    if (accessToken) {
        self.token = accessToken;
        self.isLinked = YES;
    }
}

- (void)willDelete {
    [super willDelete];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"adn_access_token"];
    [self.keychain removeObjectForKey:tokenName];
}

- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];

    NSURL *url = [NSURL URLWithString:@"https://alpha.app.net/oauth/"];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    NSMutableURLRequest *authRequest = [httpClient requestWithMethod:@"POST" path:@"access_token" parameters:@{
            @"client_id" : ADN_CLIENT_ID,
            @"password_grant_secret" : ADN_PASSWORD_GRANT_SECRET,
            @"grant_type" : @"password",
            @"username" : _username,
            @"password" : _password,
            @"scope" : @"basic,stream,email,write_post,files"
    }];

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:authRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"Operation Succeeded --> %@", responseObject);
        [self adnAuthorizeDidCompleteWithAccessToken:responseObject[@"access_token"]];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        [self.setupManager network:self setupCompleted:NO properties:@{
                @"error" : failure.description
        }];
    }];
    [operation start];
}

- (void)adnAuthorizeDidCompleteWithAccessToken:(NSString *)token {
    self.isLinked = YES;
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"adn_access_token"];
    [self.keychain setObject:token forKey:tokenName];
    self.token = token;
    [self.setupManager network:self setupCompleted:YES properties:@{
            @"title" : _username
    }];
}

- (void)postUpdate:(PCSocialActivity *)activity {
    self.currentActivity = activity;
    if (_currentActivity.messageLink == nil && (_currentActivity.messageMedia.videoData || _currentActivity.messageMedia.imageData)) {
        //post a file first
        [self postFileFromCurrentActivity];
    } else {
        //post a message or message w/link
        [self postMessageFromCurrentActivityWithAnnotation:nil];
    }
}

- (void)postFileFromCurrentActivity {
    NSURL *url = [NSURL URLWithString:ADN_BASE_URL];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _token]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    
    NSString *filename = [NSString stringWithFormat:@"file.%@", [_currentActivity.messageMedia.mimeType componentsSeparatedByString:@"/"][1]];
    NSMutableURLRequest *postRequest = [httpClient multipartFormRequestWithMethod:@"POST"
                                                                             path:@"stream/0/files"
                                                                       parameters:@{
                                                                               @"type" : @"net.postcardsocial.file",
                                                                               @"public": @1
                                                                               } constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
                [formData appendPartWithFileData:(_currentActivity.messageMedia.videoData != nil) ? _currentActivity.messageMedia.videoData : _currentActivity.messageMedia.imageData
                                            name:@"content"
                                        fileName:filename
                                        mimeType:_currentActivity.messageMedia.mimeType];
            }];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:postRequest];
    BWLog(@"Headers -> %@, MIME Type -> %@", operation.request.allHTTPHeaderFields, _currentActivity.messageMedia.mimeType);
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        NSDictionary *annotation = @{
                @"type" : @"net.app.core.oembed",
                @"value" : @{
                        @"+net.app.core.file" : @{
                                @"file_id" : responseObject[@"data"][@"id"],
                                @"file_token" : responseObject[@"data"][@"file_token"],
                                @"format" : @"oembed"
                        }
                }
        };
        [self postMessageFromCurrentActivityWithAnnotation:annotation];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:failure];
    }];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9; //leave 10% of completion for actual response
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];
    [operation start];
}

- (void)postMessageFromCurrentActivityWithAnnotation:(NSDictionary *)annotation {
    NSURL *url = [NSURL URLWithString:ADN_BASE_URL];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    [httpClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _token]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:@{
            @"text" : [_currentActivity messageWithLinkFittingCharacterLimit:(NSUInteger)self.charLimit],
    }];

    if (annotation != nil) {
        BWLog(@"attaching annotation");
        dictionary[@"annotations"] = @[
                @{
                        @"type" : @"net.postcardsocial.test",
                        @"value" : @{ @"message" : @"test success" },
                },
                annotation
        ];
    }

    NSMutableURLRequest *postRequest = [httpClient requestWithMethod:@"POST" path:@"stream/0/posts?include_post_annotations=1" parameters:dictionary];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:postRequest];

    BWLog(@"Headers -> %@, Body -> %@", operation.request.allHTTPHeaderFields, [[NSString alloc] initWithData:operation.request.HTTPBody encoding:NSUTF8StringEncoding]);

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"Operation Succeeded --> %@", responseObject);
        [NetworksManager sharedInstance].currentSocialActivity.postIds[@"adn"] = responseObject[@"data"][@"id"];
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                @"permalink" : responseObject[@"data"][@"canonical_url"]
        }];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:failure];
        [Flurry logEvent:@"ADN Post Error" withParameters:@{
                @"response":  op.responseString,
                @"wasHandled": @(NO)
        }];
    }];

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9; //leave 10% of completion for actual response
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];

    [operation start];
    self.currentActivity = nil;
}

@end