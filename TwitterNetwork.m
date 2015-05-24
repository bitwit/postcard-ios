//
// Created by kylenewsome on 2012-12-22.
//

#import "TwitterNetwork.h"
#import "AccountsManager.h"
#import "PCSocialActivity.h"
#import "NSData+URLEncode.h"

@interface TwitterNetwork ()
@property(nonatomic, weak) AccountsManager *accountsManager;
@property(nonatomic, strong) NSArray *arrayOfAccounts;
@property(nonatomic, strong) ACAccount *twitterAccount;
@property(nonatomic, strong) NSString *accountIdentifier;
@end

@implementation TwitterNetwork

- (id)init {
    self = [super init];
    if (self) {
        [self initializeTwitter];
    }
    return self;
}

- (void)initializeTwitter {
    self.accountsManager = [AccountsManager sharedInstance];
    self.name = @"twitter";
    self.tag = kTwitter;
    self.charLimit = 140;
    self.acceptsImages = YES;
}

#pragma mark - NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initializeTwitter];
        self.accountIdentifier = [aDecoder decodeObjectForKey:@"accountIdentifier"];

        ACAccountType *accountType = [_accountsManager.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

        [_accountsManager.accountStore requestAccessToAccountsWithType:accountType
                                                               options:nil completion:^(BOOL granted, NSError *error) {

            if (granted && error == nil) {
                self.arrayOfAccounts = [_accountsManager.accountStore accountsWithAccountType:accountType];

                for (ACAccount *account in _arrayOfAccounts) {
                    if ([account.identifier isEqualToString:_accountIdentifier]) {
                        self.twitterAccount = account;
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"Twitter Account not found", nil)
                                                                      message:NSLocalizedString(@"Postcard was unable to prepare your Twitter account. Please visit setup and confirm your settings.", nil)
                                                                     delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                            otherButtonTitles:nil];

                    [alert show];
                });
            }
        }];


    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:_accountIdentifier forKey:@"accountIdentifier"];
}

#pragma mark - Network
- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager {
    [super getAccessWithSetupManager:setupManager];
    ACAccountType *accountType = [_accountsManager.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

    [_accountsManager.accountStore requestAccessToAccountsWithType:accountType
                                                           options:nil completion:^(BOOL granted, NSError *error) {
        if (error) {
            [self.setupManager network:self setupCompleted:NO properties:@{
                    @"message" : error.description
            }];
            return;
        }

        if (granted) {
            BWLog(@"TW Access granted");

            self.arrayOfAccounts = [_accountsManager.accountStore accountsWithAccountType:accountType];

            NSMutableArray *options = [NSMutableArray arrayWithCapacity:_arrayOfAccounts.count];

            for (ACAccount *account in _arrayOfAccounts) {
                [options addObject:[NSString stringWithFormat:@"@%@",
                                                              account.username]];
            }

            if (options.count == 0) {
                [self.setupManager network:self setupCompleted:NO properties:@{
                        @"message" : @"You must set up a Twitter account in your iOS device's General Settings first."
                }];
            } else {
                [self.setupManager network:self showAccountSelectionOptions:options];
            }
        } else {
            [self.setupManager network:self setupCompleted:NO properties:@{
                    @"message" : @"Access not granted, check your phone's settings"
            }];
        }

    }];
}

- (void)accountSelected:(NSUInteger)index {
    self.twitterAccount = [_arrayOfAccounts objectAtIndex:index];
    self.accountIdentifier = _twitterAccount.identifier;
    self.isLinked = YES;
    [self.setupManager network:self setupCompleted:YES properties:@{
            @"title" : [NSString stringWithFormat:@"@%@", _twitterAccount.username]
    }];

    [self synchronizePeople:nil];
}

- (void)postUpdate:(PCSocialActivity *)activity {
    [super postUpdate:activity];

    SLRequest *postRequest;
    if (activity.isFromAHost && activity.hostNetwork == self.tag) {
        NSString *stringUrl = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json", activity.hostId];
        NSURL *requestURL = [NSURL URLWithString:stringUrl];
        postRequest = [SLRequest
                requestForServiceType:SLServiceTypeTwitter
                        requestMethod:SLRequestMethodPOST
                                  URL:requestURL parameters:nil];

    } else {
        NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
        NSString *message = activity.message;

        if (activity.messageLink) {
            message = [activity messageWithLinkFittingCharacterLimit:(NSUInteger) self.charLimit];
        } else if (activity.messageMedia.image) {
            requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"];
        }

        postRequest = [SLRequest
                requestForServiceType:SLServiceTypeTwitter
                        requestMethod:SLRequestMethodPOST
                                  URL:requestURL parameters:@{@"status" : message}];

        if (activity.messageLink == nil && activity.messageMedia.imageData) {
            [postRequest addMultipartData:activity.messageMedia.imageData withName:@"media[]" type:@"image/jpg" filename:nil];
        }
    }

    postRequest.account = _twitterAccount;

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:postRequest.preparedURLRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWNetLog(@"Twitter Network message response %@", responseObject);
        [[NetworksManager sharedInstance] network:self didCompletePostingWithInfo:@{
                @"id" : responseObject[@"id_str"],
                @"permalink" : [NSString stringWithFormat:@"https://twitter.com/%@/status/%@", responseObject[@"user"][@"screen_name"], responseObject[@"id_str"]]
        }];
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Twitter Network error - %@ %@", failure, op.responseData.stringWithoutURLEncoding);
        NSError *responseError = [NSError errorWithDomain:failure.description code:op.response.statusCode userInfo:nil];
        [Flurry logEvent:@"Twitter Post Error" withParameters:@{
                @"response" : (op.responseString != nil) ? op.responseString : @"(Null response)",
                @"error": failure.localizedDescription,
                @"wasHandled" : @(NO)
        }];
        @try {
            id responseObject = [NSJSONSerialization JSONObjectWithData:op.responseData options:0 error:nil];
            [[NetworksManager sharedInstance] network:self didFailWithError:responseError];
            [self handlePostingErrorCode:[responseObject[@"errors"][0][@"code"] integerValue] withSuccessSelector:nil];
        }
        @catch (NSException *e) {
            BWLog(@"Couldn't evaluate error from twitter");
            [[NetworksManager sharedInstance] network:self didFailWithError:failure];
        }
    }];

    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        BWNetLog(@"Sent %lld of %lld bytes", totalBytesWritten, totalBytesExpectedToWrite);
        double fraction = (double) totalBytesWritten / totalBytesExpectedToWrite;
        fraction *= 0.9;
        [[NetworksManager sharedInstance] network:self updatedProgress:fraction];
    }];
    [operation start];
}

- (void)handlePostingErrorCode:(NSInteger)code withSuccessSelector:(SEL)selector {
    //NSString *errorMessage = nil;
    BWLog(@"Handling error code: %d", code);
    switch (code) {
        case 220: {
            SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Twitter account @%@ not authorized", nil), _twitterAccount.username]
                                                                  message:NSLocalizedString(@"You may need to reenter your username and password in your General Settings before it will work", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
            [alertView show];
            //errorMessage = @"You must set up reenter your username and password in your iOS device's General Settings first.";
        }
            break;
        default:
            BWLog(@"Unhandled error type");
            //errorMessage = @"Error getting access to Facebook.";
            break;
    }
}

- (void)synchronizePeople:(NSString *)cursor {
    BWLog(@"Synchronizing People");
    NSURL *requestURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/friends/list.json"];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
            @"count" : @"200",
            @"skip_status" : @1,

    }];

    if (cursor != nil) {
        params[@"cursor"] = cursor;
    }

    SLRequest *getRequest = [SLRequest
            requestForServiceType:SLServiceTypeTwitter
                    requestMethod:SLRequestMethodGET
                              URL:requestURL parameters:params];

    getRequest.account = _twitterAccount;

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:getRequest.preparedURLRequest];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject) {
        BWLog(@"%@", op.response.allHeaderFields);
        NSString *remainingLimit = op.response.allHeaderFields[@"x-rate-limit-remaining"];
        NSString *nextCursor = responseObject[@"next_cursor_str"];
        NSMutableArray *users = [NSMutableArray arrayWithCapacity:[responseObject[@"users"] count]];
        for (NSDictionary *userData in responseObject[@"users"]) {
            [users addObject:@{
                    @"userId" : userData[@"id_str"],
                    @"fullName" : userData[@"name"],
                    @"username" : userData[@"screen_name"],
            }];
        }

        [[PCDataDelegate sharedInstance] handlePersonsImport:users];
        if (![nextCursor isEqualToString:@"0"] && remainingLimit.integerValue > 0) {
            //still more contents available so try...
            [self synchronizePeople:nextCursor];
        }
    }                                failure:^(AFHTTPRequestOperation *op, NSError *failure) {
        BWNetLog(@"Twitter Network error - %@ %@", failure, op.responseData.stringWithoutURLEncoding);

        [Flurry logEvent:@"Twitter People Sync Error" withParameters:@{
                @"headers" : op.response.allHeaderFields,
                @"response" : op.responseString,
                @"wasHandled" : @(NO)
        }];

        if (op.response.statusCode == 401) {
            SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Twitter account @%@ not authorized", nil), _twitterAccount.username]
                                                                  message:NSLocalizedString(@"You may need to reenter your username and password in your General Settings before it will work", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
            [alertView show];
        }

    }];
    [operation start];
}

@end