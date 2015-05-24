//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "OptionCell.h"


@implementation OptionCell

- (void)prepareForReuse {
    [super prepareForReuse];
    _iconImageView.hidden = NO;
    _activityIndicator.hidden = YES;
    [_activityIndicator stopAnimating];
}

- (void)activate {
    _iconImageView.hidden = YES;
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
}

- (void)deactivate {
    _iconImageView.hidden = NO;
    _activityIndicator.hidden = YES;
    [_activityIndicator stopAnimating];
}

@end