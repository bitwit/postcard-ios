//
// Created by Kyle Newsome on 2013-10-12.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PCWebViewController.h"

@implementation PCWebViewController

-(void)viewDidLoad {
    BWLog(@"web view %@", _webView);
    _webView.scrollView.backgroundColor = [UIColor whiteColor];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:_initialURL];
   [_webView loadRequest:urlRequest];
    _webView.delegate = self;
   _navBar.topItem.title = _initialURL.absoluteString;
   _navBar.delegate = self;
}

-(void)dealloc{
    BWLog(@"Web VC Deallocating");
}

-(UIBarPosition)positionForBar:(id <UIBarPositioning>)bar{
    return UIBarPositionTopAttached;
}

-(IBAction)back{

}

-(IBAction)forward{

}

-(IBAction)close{
   [self dismissViewControllerAnimated:YES completion:^{
       BWLog(@"Web View Close Complete");
   }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _activityIndicator.hidden = YES;
    [_activityIndicator stopAnimating];
    NSString *theTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    _navBar.topItem.title = theTitle;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {

}


@end