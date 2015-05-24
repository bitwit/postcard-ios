//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PCSuggestionSystemView.h"

@interface PCToolbarView : UIView

//Options Sheet
@property(nonatomic, weak) IBOutlet UIView *mainView;  //container view
@property(nonatomic, weak) IBOutlet PCSuggestionSystemView *suggestionSystemView;

@property(nonatomic, weak) IBOutlet UIView *networkCountView;
@property(nonatomic, weak) IBOutlet UIImageView *networkCountBGImageView;
@property(nonatomic, weak) IBOutlet UILabel *networkCountLabel;
@property(nonatomic, weak) IBOutlet UIButton *networksButton;
@property(nonatomic, weak) IBOutlet UIButton *cameraButton;
@property(nonatomic, weak) IBOutlet UIButton *attachmentButton;
@property(nonatomic, weak) IBOutlet UIImageView *cameraAttachmentIndicator;
@property(nonatomic, weak) IBOutlet UIImageView *linkAttachmentIndicator;
@property(nonatomic, weak) IBOutlet UILabel *postCharacterCount;

- (void)showMainOptions;
- (void)hideMainOptions;

@end