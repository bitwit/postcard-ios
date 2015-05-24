//
//  OAuth1WebViewController.m
//  Simple-OAuth1
//
//  Created by Christian Hansen on 02/12/12.
//  Copyright (c) 2012 Christian-Hansen. All rights reserved.
//

#import "OAuth1WebViewController.h"
#import "OAuth1Controller.h"

@interface OAuth1WebViewController ()

@property (nonatomic, strong) OAuth1Controller *oauth1Controller;
@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic, strong) NSString *oauthTokenSecret;

@property(copy) void (^accessCompletionHandler)(BOOL, NSDictionary *);

@end

@implementation OAuth1WebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)dealloc{
    BWLog(@"OAUTH 1 WVC DEALLOCATING");
}

-(UIBarPosition)positionForBar:(id <UIBarPositioning>)bar{
    BWLog(@"positionForBar");
    return UIBarPositionTopAttached;
}

- (void)setupAuthWithCompletion:(void (^)(BOOL success, NSDictionary *tokenData))handler {
    self.accessCompletionHandler = handler;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.oauth1Controller = [[OAuth1Controller alloc] init];
    [self.oauth1Controller loginWithWebView:self.webView completion:^(NSDictionary *oauthTokens, NSError *error) {
        if (!error) {
            // Store your tokens for authenticating your later requests, consider storing the tokens in the Keychain
            self.oauthToken = oauthTokens[@"oauth_token"];
            self.oauthTokenSecret = oauthTokens[@"oauth_token_secret"];
            BWLog(@"Tumblr Authenticated -> \ntoken %@ \nsecret %@", _oauthToken, _oauthTokenSecret);
            self.accessCompletionHandler(YES, oauthTokens);
        } else {
            BWLog(@"Error authenticating: %@", error.localizedDescription);
            self.accessCompletionHandler(NO, nil);
        }
        self.oauth1Controller = nil;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)cancelTapped:(id)sender
{
    self.webView.delegate = nil;
    self.accessCompletionHandler(NO, nil);
}

@end
