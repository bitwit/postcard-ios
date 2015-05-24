//
// Created by Kyle Newsome on 2013-06-10.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

//


#import <Foundation/Foundation.h>
#import "ConnectedNetwork.h"

@interface NetworkProgressView : UIView

@property(nonatomic, weak) IBOutlet UILabel *titleLabel;
@property(nonatomic, weak) IBOutlet UILabel *messageLabel;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak) IBOutlet UIImageView *hostIconView;
@property(nonatomic, weak) IBOutlet UIImageView *imageView;
@property(nonatomic, weak) IBOutlet NSLayoutConstraint *hostIconToNetworkSpacing;

@property(nonatomic, weak) IBOutlet UIProgressView *progressView;
@property(nonatomic, weak) ConnectedNetwork *connectedNetwork;

- (void)updateProgress:(float)progress;
- (void)updateProgressWithError:(float)progress andMessage:(NSString *)message;
- (void)updateProgressWithMessage:(NSString *)message;

@end