//
// Created by kylenewsome on 2012-12-22.
//

#import "FacebookNetwork.h"

#import "AccountsManager.h"
#import "PCSocialActivity.h"
#import "NSData+URLEncode.h"

typedef enum{
           FacebookPrivacyLevelMe = 0,
           FacebookPrivacyLevelFriends,
           FacebookPrivacyLevelExtended,
           FacebookPrivacyLevelPublic,
} FacebookPrivacyLevel;

@interface FacebookNetwork ()
@property(nonatomic, weak) AccountsManager *accountsManager;
@property(nonatomic, strong) ACAccount *facebookAccount;

@property(nonatomic, strong) NSArray *accounts; //for page selection
@property(nonatomic, strong) NSString *accountId; //needed for managing pages
@property(nonatomic, strong) NSString *token;

@property(nonatomic, weak) PCSocialActivity *currentActivity;
@property(nonatomic, strong) NSMutableDictionary *currentParameters;
@property(nonatomic, strong) NSString *currentRequestUrl;
@property(nonatomic, strong) SLRequest *currentActivityRequest;

//settings
@property(nonatomic, strong) NSNumber *shouldRemoveLink;
@property(nonatomic, strong) NSNumber *privacyLevel;

@end

@implementation FacebookNetwork

- (id)init {
    self = [super init];
    if (self) {
        //set creation defaults
        self.shouldRemoveLink = @YES;
        self.privacyLevel = @3; //Public
        //and standard initialization
        [self initializeFacebook];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setToken:[aDecoder decodeObjectForKey:@"token"]];
        [self setAccountId:[aDecoder decodeObjectForKey:@"accountId"]];
        [self setShouldRemoveLink:[aDecoder decodeObjectForKey:@"shouldRemoveLink"]];
        [self setPrivacyLevel:[aDecoder decodeObjectForKey:@"privacyLevel"]];
        [self initializeFacebook];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.token forKey:@"token"];
    [coder encodeObject:self.accountId forKey:@"accountId"];
    [coder encodeObject:self.shouldRemoveLink forKey:@"shouldRemoveLink"];
    [coder encodeObject:self.privacyLevel forKey:@"privacyLevel"];
}

- (void)initializeFacebook {
    self.accountsManager = [AccountsManager sharedInstance];
    self.name = @"facebook";
    self.tag = kFacebook;
    self.acceptsImages = YES;
    self.acceptsVideo = YES;

    BWLog(@"Initialize FB");
    if(self.shouldRemoveLink == nil){ //upgrading users need a default setting of YES
        BWLog(@"No remove link setting, adding the default");
        self.shouldRemoveLink = @YES;
    }

    if(self.privacyLevel == nil){ //upgrading users need a default setting of public
        BWLog(@"No privacy setting, adding the default");
        self.privacyLevel = @3; //Public
    }
}

- (NSArray *)settingFields {
    return @[  //table
            @[ //section
                    @{  //field
                            @"type" : @"SegmentedControl",
                            @"title" : @"Remove link from message?",
                            @"property" : @"shouldRemoveLink",
                            @"dataSource" : @[
                            @"No", @"Yes"
                    ],
                            @"owner" : @"instance"
                    }
            ],
            @[ //section
                    @{  //field
                            @"type" : @"SegmentedControl",
                            @"title" : @"Privacy Level",
                            @"property" : @"privacyLevel",
                            @"dataSource" : (_accountId != nil) ? @[@"Public"] : @[@"Me", @"Friends", @"Extended", @"Public"], //Pages are always public
                            @"owner" : @"instance"
                    } ,
            ],
    ];
}

- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    ACAccountType *accountType = [_accountsManager.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    [_accountsManager.accountStore requestAccessToAccountsWithType:accountType
                                                           options:@{
                                                                   ACFacebookAppIdKey : FACEBOOK_APP_KEY,
                                                                   ACFacebookPermissionsKey : @[@"email"],
                                                                   ACFacebookAudienceKey : ACFacebookAudienceEveryone
                                                           }
                                                        completion:^(BOOL granted, NSError *error) {
                                                            if (granted && error == nil) {
                                                                BWLog(@"FB Access Granted");
                                                                [self getUserAndPageOptions];
                                                            } else {
                                                                BWLog(@"FB Access Error... not granted -- %@", [error description]);
                                                                if (error != nil) {
                                                                    [self handleSetupErrorCode:error.code withSuccessSelector:nil];
                                                                } else {
                                                                    [self.setupManager network:self setupCompleted:NO properties:@{
                                                                            @"message" : @"Access not granted, check your phone's settings"
                                                                    }];
                                                                };
                                                                self.isLinked = NO;
                                                            }
                                                        }];
}

- (void)getUserAndPageOptions {
    ACAccountType *accountType = [_accountsManager.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    [_accountsManager.accountStore requestAccessToAccountsWithType:accountType
                                                           options:@{
                                                                   ACFacebookAppIdKey : FACEBOOK_APP_KEY,
                                                                   ACFacebookPermissionsKey : @[@"manage_pages"],
                                                                   ACFacebookAudienceKey : ACFacebookAudienceEveryone
                                                           }
                                                        completion:^(BOOL granted, NSError *error) {
                                                            if (granted && error == nil) {
                                                                BWLog(@"FB Access Granted");
                                                                NSArray *accounts = [_accountsManager.accountStore
                                                                        accountsWithAccountType:accountType];
                                                                self.facebookAccount = [accounts lastObject];

                                                                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/accounts", [[self.facebookAccount valueForKey:@"properties"] valueForKey:@"uid"]]];

                                                                SLRequest *feedRequest = [SLRequest
                                                                        requestForServiceType:SLServiceTypeFacebook
                                                                                requestMethod:SLRequestMethodGET
                                                                                          URL:url
                                                                                   parameters:nil];

                                                                feedRequest.account = self.facebookAccount;


                                                                [feedRequest performRequestWithHandler:^(NSData *responseData,
                                                                        NSHTTPURLResponse *urlResponse, NSError *error) {
                                                                    BWLog(@"FacebookNetwork HTTP response: %i", [urlResponse statusCode]);
                                                                    BWLog(@"FacebookNetwork accounts response %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                                                                    if ([urlResponse statusCode] == 200) {
                                                                        NSError *jsonError;
                                                                        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&jsonError];
                                                                        self.accounts = [responseDict valueForKey:@"data"];
                                                                        NSMutableArray *options = [NSMutableArray arrayWithCapacity:_accounts.count];
                                                                        [options addObject:_facebookAccount.username];
                                                                        //And admin pages
                                                                        for (NSDictionary *account in _accounts) {
                                                                            [options addObject:[NSString stringWithFormat:@"Page: %@", [account valueForKey:@"name"]]];
                                                                        }
                                                                        [self.setupManager network:self showAccountSelectionOptions:options];
                                                                    } else {
                                                                        NSError *jsonError;
                                                                        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&jsonError];
                                                                        NSNumber *errorCode = [responseDict valueForKeyPath:@"error.code"];
                                                                        [self handleSetupErrorCode:errorCode.integerValue withSuccessSelector:@selector(getUserAndPageOptions)];
                                                                    }
                                                                }];
                                                            } else {
                                                                BWLog(@"FB Access Error... not granted -- %@", [error description]);
                                                                NSString *errorMessage = (error != nil) ? error.description : @"Page management access not granted, check your phone's settings";
                                                                self.isLinked = NO;
                                                                [self.setupManager network:self setupCompleted:NO properties:@{
                                                                        @"message" : errorMessage
                                                                }];
                                                            }
                                                        }];

}

- (void)handleSetupErrorCode:(NSInteger)code withSuccessSelector:(SEL)selector {
    NSString *errorMessage = nil;
    BWLog(@"Handling error code: %d", code);
    switch (code) {
        case 6:
            errorMessage = @"You must set up Facebook in your iOS device's General Settings first.";
            break;
        case 190: {
            //reauthorize
            [_accountsManager.accountStore renewCredentialsForAccount:_facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
                BWLog(@"Renewal Result -> %d, error -> %@", renewResult, error);
                switch (renewResult) {
                    case ACAccountCredentialRenewResultRenewed:
                        if (selector != nil) {
                            [self performSelector:selector];
                        }
                        break;
                    case ACAccountCredentialRenewResultFailed:
                    case ACAccountCredentialRenewResultRejected:
                    default:
                        [self.setupManager network:self setupCompleted:NO properties:@{
                                @"message" : @"Error authorizing access to Facebook."
                        }];
                        break;
                }
            }];
        }
            break;
        default:
            BWLog(@"Unhandled error type");
            errorMessage = @"Error getting access to Facebook.";
            break;
    }

    if (errorMessage != nil) {
        [self.setupManager network:self setupCompleted:NO properties:@{
                @"message" : errorMessage
        }];
    }
}

- (void)accountSelected:(NSUInteger)index {
    self.isLinked = YES;
    if (index == 0) {
        [self.setupManager network:self setupCompleted:YES properties:@{
                @"title" : _facebookAccount.username
        }];
    } else {
        NSDictionary *account = [_accounts objectAtIndex:index - 1];
        self.accountId = [account valueForKey:@"id"];
        self.token = [account valueForKey:@"access_token"];
        [self.setupManager network:self setupCompleted:YES properties:@{
                @"title" : [account valueForKey:@"name"]
        }];
    }
}

- (void)postUpdate:(PCSocialActivity *)activity {
    [super postUpdate:activity];
    self.currentActivity = activity;
    [self buildActivityParameters];
}

- (void)buildActivityParameters {
    ACAccountType *facebookAccountType = [_accountsManager.accountStore
            accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    // Specify App ID and permissions
    NSDictionary *options = @{
            ACFacebookAppIdKey : FACEBOOK_APP_KEY,
            ACFacebookPermissionsKey : @[@"publish_stream", @"publish_actions"],
            ACFacebookAudienceKey : ACFacebookAudienceEveryone
    };

    [_accountsManager.accountStore requestAccessToAccountsWithType:facebookAccountType
                                                           options:options completion:^(BOOL granted, NSError *e) {
        if (granted) {
            NSArray *accounts = [_accountsManager.accountStore
                    accountsWithAccountType:facebookAccountType];
            self.facebookAccount = [accounts lastObject];
            self.currentParameters = [NSMutableDictionary dictionary];

            NSString *accountId;
            BWLog(@"Credentials -- Account ID %@ Token %@", _accountId, _token);
            if (_accountId != nil) {
                //Is a FB Page
                accountId = _accountId;
                _currentParameters[@"access_token"] = _token;
            } else {
                //Is a personal FB feed
                accountId = [[self.facebookAccount valueForKey:@"properties"] valueForKey:@"uid"];
                switch(self.privacyLevel.integerValue){
                    case FacebookPrivacyLevelMe:
                        _currentParameters[@"privacy"] = @"{\"value\":\"SELF\"}";
                        break;

                    case FacebookPrivacyLevelFriends:
                        _currentParameters[@"privacy"] = @"{\"value\":\"ALL_FRIENDS\"}";
                        break;

                    case FacebookPrivacyLevelExtended:
                        _currentParameters[@"privacy"] = @"{\"value\":\"FRIENDS_OF_FRIENDS\"}";
                        break;

                    case FacebookPrivacyLevelPublic:
                    default:
                        _currentParameters[@"privacy"] = @"{\"value\":\"EVERYONE\"}";
                        break;
                }
            }

            self.currentRequestUrl = [NSString stringWithFormat:@"https://graph.facebook.com/%@/feed", accountId];
            _currentParameters[@"message"] = (_shouldRemoveLink.boolValue) ? _currentActivity.message : _currentActivity.messageWithLink;
            if (_currentActivity.messageLink) {
                _currentParameters[@"link"] = _currentActivity.messageLink.url;
            } else if (_currentActivity.messageMedia.videoData) {
                self.currentRequestUrl = [NSString stringWithFormat:@"https://graph.facebook.com/%@/videos", accountId];
                [_currentParameters removeObjectForKey:@"message"];
                _currentParameters[@"title"] = _currentActivity.message;
                _currentParameters[@"description"] = _currentActivity.message;
                _currentParameters[@"contentType"] = @"video/mp4";
            } else if (_currentActivity.messageMedia.image) {
                self.currentRequestUrl = [NSString stringWithFormat:@"https://graph.facebook.com/%@/photos", accountId];
            }

            BWLog(@"Facebook parameters -> %@", _currentParameters);

            [self buildActivityRequest];
        }
        else {
            BWLog(@"FacebookNetwork post error-> %@", [e description]);
            [[NetworksManager sharedInstance] network:self didFailWithError:e];
        }
    }];
}

- (void)buildActivityRequest {
    NSURL *feedURL = [NSURL URLWithString:_currentRequestUrl];
    self.currentActivityRequest = [SLRequest
            requestForServiceType:SLServiceTypeFacebook
                    requestMethod:SLRequestMethodPOST
                              URL:feedURL
                       parameters:_currentParameters];


    if (_currentActivity.messageLink == nil && _currentActivity.messageMedia.videoData) {
        [_currentActivityRequest addMultipartData:_currentActivity.messageMedia.videoData
                                         withName:@"video.mp4"
                                             type:@"video/mp4"
                                         filename:@"video.mp4"];
    } else if (_currentActivity.messageLink == nil && _currentActivity.messageMedia.imageData) {
        [_currentActivityRequest addMultipartData:_currentActivity.messageMedia.imageData withName:@"picture" type:@"image/jpg" filename:nil];
    }

    if (_accountId == nil) {
        _currentActivityRequest.account = self.facebookAccount;
    }

    [self sendActivityRequest];
}

- (void)sendActivityRequest {
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:_currentActivityRequest.preparedURLRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"FacebookNetwork message response %@", responseObject);
        [_currentActivity.postIds setValue:[responseObject valueForKey:@"id"] forKey:@"facebook"];
        NSString *accountId;
        if (_accountId != nil) {
            accountId = _accountId;
        } else {
            accountId = [[self.facebookAccount valueForKey:@"properties"] valueForKey:@"uid"];
        }
        NSString *postId = [responseObject[@"id"] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@_", accountId]
                                                                            withString:@""];
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                @"id" : postId,
                @"permalink" : [NSString stringWithFormat:@"http://www.facebook.com/%@/posts/%@", accountId, postId]
        }];
        self.currentActivity = nil;
        self.currentRequestUrl = nil;
        self.currentActivityRequest = nil;
        self.currentParameters = nil;
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {

        NSError *parseError;
        NSDictionary *errorJson = [NSJSONSerialization JSONObjectWithData:op.responseData options:NSJSONReadingMutableContainers error:&parseError];

        BOOL handledError = NO;
        if (parseError == nil && [[errorJson valueForKeyPath:@"error.code"] isEqualToNumber:@1500]) {
            BWNetLog(@"Facebook URL Error, retrying with link in message");
            [_currentParameters removeObjectForKey:@"link"];
            _currentParameters[@"message"] = _currentActivity.messageWithLink;
            [self buildActivityRequest];
            handledError = YES;
        } else {
            BWNetLog(@"Operation failed -- status code %d - \n %@ \n %@", op.response.statusCode, [op response].allHeaderFields, [op responseString]);
            [[NetworksManager sharedInstance] network:self didFailWithError:failure];
            self.currentActivity = nil;
            self.currentRequestUrl = nil;
            self.currentActivityRequest = nil;
            self.currentParameters = nil;
        }
        [Flurry logEvent:@"Faceboook Post Error" withParameters:@{
                @"response" : op.responseString,
                @"wasHandled" : @(handledError)
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