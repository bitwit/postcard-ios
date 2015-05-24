//
// Created by Kyle Newsome on 2013-10-07.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class PCViewController;
@class PCMessageTextView;

typedef enum {
    PCMessageTextViewStateNormal = 0,
    PCMessageTextViewStateHashtag,
    PCMessageTextViewStateMention
} PCMessageTextViewState;

@protocol PCMessageTextViewDelegate <NSObject>
- (void)messageTextView:(PCMessageTextView *)messageTextView enteringState:(PCMessageTextViewState)state;

- (void)messageTextView:(PCMessageTextView *)messageTextView currentSpecialWordText:(NSString *)text;
@end


@interface PCMessageTextView : UITextView <UITextViewDelegate, UIKeyInput>

@property(nonatomic, weak) PCViewController *postcardVC;
@property(nonatomic) PCMessageTextViewState state;
@property(nonatomic, weak) IBOutlet id <PCMessageTextViewDelegate> stateDelegate;

- (void)styleMessage;

- (NSArray *)getHashtags;

- (void)setTextForCurrentTag:(NSString *)text;

- (void)setTextForCurrentMention:(NSString *)text;
@end