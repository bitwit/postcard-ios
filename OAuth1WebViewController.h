//
//  OAuth1WebViewController.h
//  Simple-OAuth1
//
//  Created by Christian Hansen on 02/12/12.
//  Copyright (c) 2012 Christian-Hansen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAuth1WebViewController : UIViewController  <UINavigationBarDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

- (void)setupAuthWithCompletion:(void (^)(BOOL success, NSDictionary *tokenData))handler;

@end
