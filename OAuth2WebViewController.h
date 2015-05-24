//
// Created by Kyle Newsome on 2013-09-16.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@interface OAuth2WebViewController : UIViewController <UIWebViewDelegate, UINavigationBarDelegate>

@property(nonatomic, weak) id delegate;
@property(nonatomic, weak) IBOutlet UIWebView *webView;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setupAuthWithParameters:(NSDictionary *)params viewController:(UIViewController *)viewController completion:(void (^)(BOOL success, NSString *token))handler;

- (IBAction)cancel;
@end