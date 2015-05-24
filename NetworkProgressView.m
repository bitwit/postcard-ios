//
// Created by Kyle Newsome on 2013-06-10.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

//


#import "NetworkProgressView.h"

@implementation NetworkProgressView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    BWLog(@"Network Progress view loaded from nib");
    return self;
}

- (void)setConnectedNetwork:(ConnectedNetwork *)network {
    _connectedNetwork = network;
    _titleLabel.text = network.title;

    _imageView.image = [[UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", _connectedNetwork.networkId]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _imageView.tintColor = [PCColorPalette darkBlueColor];

    _activityIndicator.hidden = YES;
    if (network.isHost.boolValue) {
        _hostIconView.hidden = NO;
        _hostIconView.image = [_hostIconView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _hostIconToNetworkSpacing.priority = 910; //increasing priority
    } else {
        _hostIconView.hidden = YES;
        _hostIconToNetworkSpacing.priority = 890; //lowering priority
    }
    [self updateConstraints];
}

- (void)updateProgress:(float)progress {
    [_progressView setProgress:progress animated:YES];
    if (progress >= 1.0f) {
        if (_activityIndicator.hidden) {
            [UIView animateWithDuration:0.22f animations:^{
                _activityIndicator.alpha = 0.0f;
                [_activityIndicator stopAnimating];
            }];
        }
    }
}

- (void)updateProgressWithError:(float)progress andMessage:(NSString *)message {
    [self updateProgress:progress];

    _titleLabel.textColor = [PCColorPalette orangeColor];
    _imageView.tintColor = [PCColorPalette orangeColor];
    _progressView.progressTintColor = [PCColorPalette orangeColor];

    /*
    if (message != nil) {
        _messageLabel.textColor = [PCColorPalette orangeColor];
        _messageLabel.text = message;
        if (_messageLabel.hidden) {
            _messageLabel.hidden = NO;
            _messageLabel.alpha = 0.0f;
            [UIView animateWithDuration:0.16f animations:^{
                _messageLabel.alpha = 1.0f;
            }];
        }
    } else {
        _messageLabel.hidden = YES;
    }
    */

    CGFloat t = 6.0;
    CGAffineTransform translateRight = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0);

    self.transform = translateLeft;
    [UIView animateWithDuration:0.07 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:2.0];
        self.transform = translateRight;
    }                completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.transform = CGAffineTransformIdentity;
            }                completion:NULL];
        }
    }];
}

- (void)updateProgressWithMessage:(NSString *)message {
    _messageLabel.text = message;
    if (_messageLabel.hidden) {
        _messageLabel.hidden = NO;
        _messageLabel.alpha = 0.0f;
        _activityIndicator.hidden = NO;
        _activityIndicator.alpha = 0.0f;
        [UIView animateWithDuration:0.22f animations:^{
            _messageLabel.alpha = 1.0f;
            _activityIndicator.alpha = 1.0f;
            [_activityIndicator startAnimating];
        }];
    }
}


@end