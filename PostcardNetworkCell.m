//
//  PostcardNetworkCell.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-08-24.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "PostcardNetworkCell.h"

@implementation PostcardNetworkCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
        bgView.backgroundColor = [PCColorPalette lightOrangeColor];
        self.selectedBackgroundView = bgView;
        self.isHost = NO;
        BWLog(@"");
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
    bgView.backgroundColor = [PCColorPalette lightOrangeColor];
    self.selectedBackgroundView = bgView;
    self.isHost = NO;

    //self.backViewbackgroundColor = [PCColorPalette lightBlueColor];
    return self;
}

- (void)setIsHost:(BOOL)isHost {
    [self setIsHost:isHost animated:NO];
}

- (void)setIsHost:(BOOL)isHost animated:(BOOL)shouldAnimate {
    _isHost = isHost;
    if (_isHost) {
        if (!_hostToNetworkImageLayoutConstraint) {
            self.hostToNetworkImageLayoutConstraint = [NSLayoutConstraint constraintWithItem:_networkImageView
                                                                                   attribute:NSLayoutAttributeLeading
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:_hostImageView
                                                                                   attribute:NSLayoutAttributeTrailing
                                                                                  multiplier:1.0f
                                                                                    constant:8.0f];
            _hostToNetworkImageLayoutConstraint.priority = 910;
            BWLog(@"added constraint -> %@", _hostToNetworkImageLayoutConstraint);
            [self addConstraint:_hostToNetworkImageLayoutConstraint];
        } else {
            _hostToNetworkImageLayoutConstraint.priority = 910;
        }
    } else {
        if (_hostToNetworkImageLayoutConstraint) {
            _hostToNetworkImageLayoutConstraint.priority = 890;
        }
    }
    if (shouldAnimate) {
        [UIView animateWithDuration:0.26f animations:^{
            [self layoutIfNeeded];
            _hostImageView.alpha = (_isHost) ? 1.0f : 0.0f;
        }                completion:nil];
    } else {
        _hostImageView.alpha = (_isHost) ? 1.0f : 0.0f;
        [self updateConstraints];
    }
}

- (UIImageView *)hostBackImageView {
    if (!_hostBackImageView) {
        _hostBackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(self.frame), CGRectGetHeight(self.frame))];

        NSString *imageName = (_isHost) ? @"cell-host-cancel" : @"cell-host";
        if (!_canHost) imageName = @"cell-na";
        [_hostBackImageView setImage:[[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _hostBackImageView.tintColor = [UIColor grayColor];
        [_hostBackImageView setContentMode:UIViewContentModeCenter];
        [self.backView addSubview:_hostBackImageView];
    }
    return _hostBackImageView;
}

- (UIImageView *)settingsBackImageView {
    if (!_settingsBackImageView) {
        _settingsBackImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.contentView.frame), 0, CGRectGetHeight(self.frame), CGRectGetHeight(self.frame))];
        [_settingsBackImageView setImage:[[UIImage imageNamed:@"cell-settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        _settingsBackImageView.tintColor = [UIColor grayColor];
        [_settingsBackImageView setContentMode:UIViewContentModeCenter];
        [self.backView addSubview:_settingsBackImageView];
    }
    return _settingsBackImageView;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isHost = NO;
    self.textLabel.textColor = [UIColor blackColor];
    self.detailTextLabel.text = nil;
    self.detailTextLabel.textColor = [UIColor grayColor];
    [self setUserInteractionEnabled:YES];
    self.imageView.alpha = 1;
    self.accessoryView = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    [self.contentView setHidden:NO];
    [self cleanupBackView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _hostImageView.image = [_hostImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _hostImageView.tintColor = [PCColorPalette darkBlueColor];
}

- (void)animateContentViewForPoint:(CGPoint)point velocity:(CGPoint)velocity {
    [super animateContentViewForPoint:point velocity:velocity];
    if (point.x > 0) { //Panning toward HOST
        // set the checkmark's frame to match the contentView
        [self.hostBackImageView setFrame:CGRectMake(MIN(CGRectGetMinX(self.contentView.frame) - CGRectGetWidth(self.hostBackImageView.frame), 0), CGRectGetMinY(self.hostBackImageView.frame), CGRectGetWidth(self.hostBackImageView.frame), CGRectGetHeight(self.hostBackImageView.frame))];
        [UIView transitionWithView:_hostBackImageView
                          duration:0.13f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            if (point.x >= CGRectGetHeight(self.frame)) {
                                if (_canHost) {
                                    _hostBackImageView.tintColor = (_isHost) ? [PCColorPalette orangeColor] : [PCColorPalette darkBlueColor];
                                }
                            } else {
                                _hostBackImageView.tintColor = [UIColor grayColor];
                            }
                        }
                        completion:nil];
    } else if (point.x < 0) { //Panning toward settings view
        // set the X's frame to match the contentView
        [self.settingsBackImageView setFrame:CGRectMake(MAX(CGRectGetMaxX(self.frame) - CGRectGetWidth(self.settingsBackImageView.frame), CGRectGetMaxX(self.contentView.frame)), CGRectGetMinY(self.settingsBackImageView.frame), CGRectGetWidth(self.settingsBackImageView.frame), CGRectGetHeight(self.settingsBackImageView.frame))];
        [UIView transitionWithView:_hostBackImageView
                          duration:0.13f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            if (-point.x >= CGRectGetHeight(self.frame)) {
                                _settingsBackImageView.tintColor = [PCColorPalette darkBlueColor];
                            } else {
                                _settingsBackImageView.tintColor = [UIColor grayColor];
                            }
                        }
                        completion:nil];
    }
}

- (void)resetCellFromPoint:(CGPoint)point velocity:(CGPoint)velocity {
    [super resetCellFromPoint:point velocity:velocity];
    if (point.x > 0) {
        // Host related
        //by this point, the cell will have it's isHost property set by the delegate already
        if (!_isHost) {
            // user did not swipe far enough, animate the image back
            [UIView animateWithDuration:self.animationDuration
                             animations:^{
                                 [self.hostBackImageView setFrame:CGRectMake(-CGRectGetWidth(self.hostBackImageView.frame), CGRectGetMinY(self.hostBackImageView.frame), CGRectGetWidth(self.hostBackImageView.frame), CGRectGetHeight(self.hostBackImageView.frame))];
                             }];
        }
    } else if (point.x < 0) {
        if (-point.x <= CGRectGetHeight(self.frame)) {
            //Settings
            // user did not swipe far enough, animate the image back
            [UIView animateWithDuration:self.animationDuration
                             animations:^{
                                 [self.settingsBackImageView setFrame:CGRectMake(CGRectGetMaxX(self.frame), CGRectGetMinY(self.settingsBackImageView.frame), CGRectGetWidth(self.settingsBackImageView.frame), CGRectGetHeight(self.settingsBackImageView.frame))];
                             }];
        }
    }
}

- (void)cleanupBackView {
    [super cleanupBackView];
    [_hostBackImageView removeFromSuperview];
    _hostBackImageView = nil;
    [_settingsBackImageView removeFromSuperview];
    _settingsBackImageView = nil;
}

@end
