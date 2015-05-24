//
// Created by Kyle Newsome on 2013-09-16.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "OAuth2WebViewController.h"
#import "NSString+URLEncode.h"


@interface OAuth2WebViewController ()

@property(nonatomic, strong) NSDictionary *authParams;
@property(copy) void (^accessCompletionHandler)(BOOL, NSString *);

@end

@implementation OAuth2WebViewController

-(void)dealloc{
    BWLog(@"OAUTH 2 WVC DEALLOCATING");
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(UIBarPosition)positionForBar:(id <UIBarPositioning>)bar{
	BWLog(@"positionForBar");
	return UIBarPositionTopAttached;
}

- (void)setupAuthWithParameters:(NSDictionary *)params viewController:(UIViewController *)viewController completion:(void (^)(BOOL success, NSString *token))handler {
    self.accessCompletionHandler = handler;
    self.authParams = params;
}

-(NSDictionary *)parametersFromUrl:(NSString *)urlString{
    NSString *query = [urlString componentsSeparatedByString:@"?"].lastObject;
    NSArray *queryElements = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    for (NSString *element in queryElements) {
        NSArray *keyVal = [element componentsSeparatedByString:@"="];
        if (keyVal.count > 0) {
            NSString *variableKey = [keyVal objectAtIndex:0];
            NSString *value = (keyVal.count == 2) ? [keyVal lastObject] : nil;
            [parameters setValue:value.urldecode forKey:variableKey];
        }
    }
    return parameters;
}
-(void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	NSURL *authUrl = [NSURL URLWithString:[_authParams valueForKey:@"auth_url"]];
	BWLog(@"webview %@", _webView);
    [_webView loadRequest:[NSURLRequest requestWithURL:authUrl]];
}

#pragma mark -  UIWebView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    NSString *urlString = url.absoluteString;

    BWLog(@"%@", urlString);

    NSString *codeString = [NSString stringWithFormat:@"%@=", [_authParams valueForKey:@"code_title"]];
    if ([urlString rangeOfString:codeString].location != NSNotFound) {
        BWLog(@"THIS IS THE CODE RESPONSE");
        // Successful Signup
        NSDictionary *parameters = [self parametersFromUrl:urlString];
        [self getAccessTokenWithCode:[parameters valueForKey:[_authParams valueForKey:@"code_title"]]];
        [webView stopLoading];
        return NO;
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _activityIndicator.hidden = YES;
    [_activityIndicator stopAnimating];
}

#pragma mark -
- (void)getAccessTokenWithCode:(NSString *)code {
    BWLog(@"code -> %@", code);
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[_authParams valueForKey:@"base_token_url"]]];
    [httpClient setDefaultHeader:@"Accept" value:@"application/json"];
    [httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:[_authParams valueForKey:@"token_post_data"]];
    [parameters setValue:code forKey:[_authParams valueForKey:@"code_title"]];

    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:[_authParams valueForKey:@"token_path"] parameters:parameters];

    BWLog(@"\n %@ \n\n %@ \n\n %@", request.URL.absoluteString, request.allHTTPHeaderFields, [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    
    __weak OAuth2WebViewController *_self = self;

    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *op, id responseObject){
        BWLog(@"Operation Succeeded --> %@", responseObject);
        NSString *token = [responseObject valueForKey:[_self.authParams valueForKey:@"token_title"]];
        _self.accessCompletionHandler(YES, token);

    } failure:^(AFHTTPRequestOperation *op, NSError *failure){
        BWLog(@"Operation failed -- %@", [op responseString]);
        _self.accessCompletionHandler(NO, nil);
    }];

    [httpClient enqueueHTTPRequestOperation:operation];
}

- (IBAction)cancel{
    self.webView.delegate = nil;
    self.accessCompletionHandler(NO, nil);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

@end