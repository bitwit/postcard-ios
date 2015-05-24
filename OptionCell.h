//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PCTableViewCell.h"


@interface OptionCell : PCTableViewCell

@property(nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic, weak) IBOutlet UILabel *titleLabel;
@property(nonatomic, weak) IBOutlet UILabel *descriptionLabel;

- (void)activate;
- (void)deactivate;

@end