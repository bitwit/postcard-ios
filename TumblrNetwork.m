//
// Created by Kyle Newsome on 2013-10-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "TumblrNetwork.h"
#import "PDKeychainBindings.h"
#import "PCSocialActivity.h"
#import "NetworkSetupViewController.h"
#import "OAuth1WebViewController.h"
#import "OAuth1Controller.h"
#import "NSString+URLEncoding.h"
#import "NSData+URLEncode.h"
#import "PCEmbedMaker.h"

#define TUMBLR_MAX_VIDEO_ATTEMPT_COUNT  30 //try for 90 seconds...
#define TUMBLR_VIDEO_ATTEMPT_TIMEOUT 3.0f

@interface TumblrNetwork ()

@property(nonatomic, weak) PDKeychainBindings *keychain;
@property(nonatomic, strong) NSString *token;
@property(nonatomic, strong) NSString *tokenSecret;
@property(nonatomic, weak) OAuth1WebViewController *authViewController;
@property(nonatomic, strong) NSArray *blogsData;
@property(nonatomic, strong) NSString *blogBaseName;

//Video url attempts
@property(nonatomic, weak) PCSocialActivity *currentActivity;
@property(nonatomic) NSUInteger videoAttemptCount;

@end

@implementation TumblrNetwork

- (id)init {
    self = [super init];
    if (self) {
        [self initializeTumblr];
    }
    return self;
}

- (void)initializeTumblr {
    self.name = @"tumblr";
    self.tag = kTumblr;
    self.usesTags = YES;
    self.acceptsImages = YES;
    self.acceptsVideo = YES;
    self.keychain = [PDKeychainBindings sharedKeychainBindings];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"tumblr_access_token"];
    self.token = [self.keychain objectForKey:tokenName];
    NSString *tokenSecretName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"tumblr_access_token_secret"];
    self.tokenSecret = [self.keychain objectForKey:tokenSecretName];
}

- (void)willDelete {
    [super willDelete];
    NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"tumblr_access_token"];
    [self.keychain removeObjectForKey:tokenName];
}


#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.blogBaseName = [aDecoder decodeObjectForKey:@"blogBaseName"];
        [self initializeTumblr];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_blogBaseName forKey:@"blogBaseName"];
}

#pragma mark - Network Setup & Settings
- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    [setupManager.networkSetupVC performSegueWithIdentifier:@"modalOAuth1WebView" sender:self];
}

- (void)webAuthViewSetup:(OAuth1WebViewController *)webAuthViewController {
    self.authViewController = webAuthViewController;
    [_authViewController setupAuthWithCompletion:^(BOOL success, NSDictionary *tokenData) {
        if (success) {
            self.token = tokenData[@"oauth_token"];
            self.tokenSecret = tokenData[@"oauth_token_secret"];
            NSString *tokenName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"tumblr_access_token"];
            [self.keychain setObject:_token forKey:tokenName];
            NSString *tokenSecretName = [NSString stringWithFormat:@"%@_%@", self.UUID, @"tumblr_access_token_secret"];
            [self.keychain setObject:_tokenSecret forKey:tokenSecretName];
            self.isLinked = YES;
            [self requestBlogsWithCompletion:^(BOOL profileSuccess, NSArray *blogs) {
                BWNetLog(@"blogs -> %@", blogs);
                self.blogsData = blogs;
                NSMutableArray *blogNames = [NSMutableArray arrayWithCapacity:blogs.count];
                for (NSDictionary *blogInfo in blogs) {
                    [blogNames addObject:blogInfo[@"name"]];
                }
                [self.setupManager network:self showAccountSelectionOptions:blogNames];
            }];
        }   else {
            [self.setupManager network:self setupCompleted:NO properties:@{
                    @"message": @"Cancelled setup"
            }];
        }
        [self.setupManager.networkSetupVC dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)accountSelected:(NSUInteger)index {
    NSDictionary *data = [_blogsData objectAtIndex:index];
    NSString *title = data[@"name"];
    NSURL *url = [NSURL URLWithString:data[@"url"]];
    self.blogBaseName = url.host;
    [self.setupManager network:self setupCompleted:YES properties:@{
            @"title" : title
    }];
}

#pragma mark - Posting/Getting data

- (NSMutableURLRequest *)preparedRequestForPath:(NSString *)path
                                     parameters:(NSDictionary *)queryParameters
                                     HTTPmethod:(NSString *)HTTPmethod {

    NSString *baseUrl = @"http://api.tumblr.com/v2/";
    NSString *fullUrl = [baseUrl stringByAppendingString:path];

    NSMutableDictionary *standardOauthParameters = [OAuth1Controller standardOauthParameters];
    standardOauthParameters[@"oauth_token"] = _token;

    NSMutableDictionary *allParameters = [NSMutableDictionary dictionaryWithDictionary:standardOauthParameters];
    if (queryParameters != nil) {
        [allParameters addEntriesFromDictionary:queryParameters];
        [allParameters removeObjectForKey:@"data[]"];
    }

    NSString *parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);

    BWLog(@"Param string -> %@", parametersString);
    NSString *baseString = [HTTPmethod stringByAppendingFormat:@"&%@&%@", fullUrl.encodeForURL, parametersString.encodeForURL];
    baseString = [baseString stringByReplacingOccurrencesOfString:@"%2C" withString:@"%252C"];  // ,
    baseString = [baseString stringByReplacingOccurrencesOfString:@"%27" withString:@"%2527"];  // '
    baseString = [baseString stringByReplacingOccurrencesOfString:@"%5B" withString:@"%255B"];  // [
    baseString = [baseString stringByReplacingOccurrencesOfString:@"%5D" withString:@"%255D"];  // ]
    baseString = [baseString stringByReplacingOccurrencesOfString:@"%2A" withString:@"%252A"];  // *
    //baseString = [baseString stringByReplacingOccurrencesOfString:@"~" withString:@"%257E"];  // ~

    BWLog(@"All parameters -> %@ \n BaseString -> %@", allParameters, baseString);

    NSString *secretString = [TUMBLR_CLIENT_SECRET.encodeForURL stringByAppendingFormat:@"&%@", _tokenSecret.encodeForURL];
    NSString *oauth_signature = [OAuth1Controller signClearText:baseString withSecret:secretString];
    standardOauthParameters[@"oauth_signature"] = oauth_signature;

    NSString *fullPath = path;
    NSString *queryString;
    if (queryParameters != nil && [HTTPmethod isEqualToString:@"GET"]) {
        queryString = CHQueryStringFromParametersWithEncoding(queryParameters, NSUTF8StringEncoding);
        fullPath = [path stringByAppendingFormat:@"?%@", queryString];
    }

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
    NSMutableURLRequest *request;

    NSData *attachmentData = queryParameters[@"data[]"];
    if (attachmentData != nil) {
        NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithDictionary:queryParameters];
        [postParams removeObjectForKey:@"data[]"];
        request = [httpClient multipartFormRequestWithMethod:HTTPmethod path:path parameters:postParams constructingBodyWithBlock:^(id <AFMultipartFormData> formData) {
            NSString *type;
            if ([queryParameters[@"type"] isEqualToString:@"video"]) {
                type = @"video/mp4";
            } else {
                type = @"image/jpeg";
            }
            [formData appendPartWithFileData:attachmentData name:@"data" fileName:@"file_data" mimeType:type];
        }];
    } else {
        request = [httpClient requestWithMethod:HTTPmethod path:fullPath parameters:queryParameters];
    }

    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *name in standardOauthParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [standardOauthParameters[name] encodeForURL]];
        [parameterPairs addObject:aPair];
    }

    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];

    BWLog(@"request body -> %@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);

    return request;
}

- (void)requestBlogsWithCompletion:(void (^)(BOOL success, NSArray *profiles))handler {
    NSMutableURLRequest *request = [self preparedRequestForPath:@"user/info" parameters:nil HTTPmethod:@"GET"];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"Operation Succeeded  --> %@", responseObject);
        handler(YES, [responseObject valueForKeyPath:@"response.user.blogs"]);
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWLog(@"Operation failed -- %@", [op responseString]);
        handler(NO, nil);
    }];
    [operation start];
}

- (void)postUpdate:(PCSocialActivity *)activity {
    [super postUpdate:activity];

    NSString *path = [NSString stringWithFormat:@"blog/%@/post", _blogBaseName];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    if (activity.tags != nil) {
        //currently only supports 1 tag maximum, so take first one
        parameters[@"tags"] = activity.tags;
    }

    if (activity.messageMedia.videoData) {
        parameters[@"type"] = @"video";
        parameters[@"caption"] = activity.message;
        parameters[@"data[]"] = activity.messageMedia.videoData;

    } else if (activity.messageMedia.image) {
        parameters[@"type"] = @"photo";
        parameters[@"caption"] = activity.message;
        parameters[@"data[]"] = activity.messageMedia.imageData;
    }
    else {
        if (activity.messageLink) {

            if([PCEmbedMaker canEmbedURL:activity.messageLink.url])   {
                parameters[@"type"] = @"video";
                parameters[@"caption"] = activity.message;
                parameters[@"embed"] = [PCEmbedMaker embedCodeForURL:activity.messageLink.url];
                BWLog(@"Embedding -> %@", parameters[@"embed"] );
            }   else {
                parameters[@"url"] = activity.messageLink.url;
                parameters[@"type"] = @"link";
                parameters[@"description"] = activity.message;

            }

        } else {
            parameters[@"type"] = @"text";
            parameters[@"body"] = activity.message;
        }
    }

    NSMutableURLRequest *request = [self preparedRequestForPath:path parameters:parameters HTTPmethod:@"POST"];

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"Operation Succeeded --> %@", responseObject);
        ConnectedNetwork *firstNetwork = activity.networks[0];
        BOOL isHost = ((Network *)firstNetwork.instance == self && firstNetwork.isHost.boolValue);
        if(isHost && activity.messageMedia.videoData){
            BWNetLog(@"Checking for videos posted");
            [[NetworksManager sharedInstance] network:self updateMessage:NSLocalizedString(@"Video processing...", nil)];
            //need a different url for videos
            self.currentActivity = activity;
            self.videoAttemptCount = 0;
            [self performSelector:@selector(checkForVideoURL) withObject:nil afterDelay:TUMBLR_VIDEO_ATTEMPT_TIMEOUT];
        }  else {
            [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                    @"id": responseObject[@"response"][@"id"],
                    @"permalink": [NSString stringWithFormat:@"http://%@/post/%@/", _blogBaseName, responseObject[@"response"][@"id"]]
            } ];
        }
    }  failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Operation failed -- %@", [op responseString]);
        [[NetworksManager sharedInstance] network:self didFailWithError:failure];
        [Flurry logEvent:@"Tumblr Post Error" withParameters:@{
                @"response":  op.responseString,
                @"wasHandled": @(NO)
        }];
    }];
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWNetLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9; //leave 10% of completion for actual response
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];
    [operation start];

}

-(void)checkForVideoURL{
    BWLog(@"Checking for valid video url of latest content");
    NSString *videosPath = [NSString stringWithFormat: @"http://api.tumblr.com/v2/blog/%@/posts/video/?api_key=%@&limit=1", _blogBaseName, TUMBLR_CLIENT_ID];

    NSMutableURLRequest *videosRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:videosPath]];
    [videosRequest setHTTPMethod:@"GET"];

    AFJSONRequestOperation *videoOperation = [[AFJSONRequestOperation alloc] initWithRequest:videosRequest];
    [videoOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *vidOperation, id videoResponseObject) {
        BWNetLog(@"videos response -> %@ Headers -> %@", videoResponseObject, vidOperation.response.allHeaderFields);
        NSDictionary *latestVideoPost = videoResponseObject[@"response"][@"posts"][0];
        if ([latestVideoPost[@"caption"] rangeOfString:_currentActivity.message].location != NSNotFound){
            [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                    @"permalink": latestVideoPost[@"post_url"]
            }];
            return;
        }   else {
            if(_videoAttemptCount > TUMBLR_MAX_VIDEO_ATTEMPT_COUNT){
                [[NetworksManager sharedInstance] network:self didFailWithError:[NSError errorWithDomain:@"Couldn't find video url" code:0 userInfo:nil]];
            } else {
                if(_videoAttemptCount == 5) { //currently 15 seconds
                    [[NetworksManager sharedInstance] network:self updateMessage:NSLocalizedString(@"May take 1 minute...", nil)];
                }
                [self performSelector:@selector(checkForVideoURL) withObject:nil afterDelay:TUMBLR_VIDEO_ATTEMPT_TIMEOUT];
            }
        }
        _videoAttemptCount++;
    } failure:^(AFHTTPRequestOperation *vidOperation, NSError *error) {
        BWNetLog(@"Operation failed -- %@", [vidOperation responseString]);
        if(_videoAttemptCount > TUMBLR_MAX_VIDEO_ATTEMPT_COUNT){
            [[NetworksManager sharedInstance] network:self didFailWithError:error];
        }   else {
            [self performSelector:@selector(checkForVideoURL) withObject:nil afterDelay:TUMBLR_VIDEO_ATTEMPT_TIMEOUT];
        }
    }];
    [videoOperation start];
}


@end