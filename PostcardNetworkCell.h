//
//  PostcardNetworkCell.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-08-24.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostcardNetworkCell : RMSwipeTableViewCell //UITableViewCell

@property(nonatomic, weak) IBOutlet UIImageView *hostImageView;
@property(nonatomic, strong) NSLayoutConstraint *hostToNetworkImageLayoutConstraint;
@property(nonatomic, weak) IBOutlet UIImageView *networkImageView;
@property(nonatomic, weak) IBOutlet UILabel *networkNameLabel;
@property(nonatomic, weak) IBOutlet UILabel *networkTypeLabel;
@property(nonatomic, weak) IBOutlet UIImageView *enabledIndicatorImageView;

@property(nonatomic) BOOL canHost;
@property(nonatomic) BOOL isHost;

//Back images
@property (nonatomic, strong) UIImageView *hostBackImageView;
@property (nonatomic, strong) UIImageView *settingsBackImageView;

- (void)setIsHost:(BOOL)isHost animated:(BOOL)shouldAnimate;
@end
