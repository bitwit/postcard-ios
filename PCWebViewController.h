//
// Created by Kyle Newsome on 2013-10-12.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface PCWebViewController : UIViewController <UIWebViewDelegate>

@property(nonatomic, weak) IBOutlet UINavigationBar *navBar;
@property(nonatomic, weak) IBOutlet UIWebView *webView;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *backButton;
@property(nonatomic, weak) IBOutlet UIBarButtonItem *forwardButton;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@property(nonatomic, strong) NSURL *initialURL;

-(UIBarPosition)positionForBar:(id <UIBarPositioning>)bar;

-(IBAction)back;
-(IBAction)forward;
-(IBAction)close;


@end