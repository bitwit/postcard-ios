//
// Created by Kyle Newsome on 2013-10-07.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "PCMessageTextView.h"
#import "PCViewController.h"
#import "PCSocialActivity.h"

@interface PCMessageTextView ()
@property(nonatomic) NSRange editingWordRange;
@end

@implementation PCMessageTextView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.delegate = self;
    _state = PCMessageTextViewStateNormal;
    return self;
}

- (void)paste:(id)sender {
    [super paste:sender];
    [self evaluateMessageLinks];
}

- (void)styleMessage {
    self.scrollEnabled = NO;
    NSError *error = NULL;
    NSString *message = self.text;
    NSRange formerRange = self.selectedRange;

    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    NSArray *matches = [detector matchesInString:message
                                         options:0
                                           range:NSMakeRange(0, [message length])];

    CGFloat fontSize = 24.0f;
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:message attributes:@{
            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize]
    }];

    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        [attString addAttributes:@{
                NSForegroundColorAttributeName : [PCColorPalette darkBlueColor],
        }                  range:matchRange];
    }

    self.attributedText = attString;
    self.selectedRange = formerRange;
    self.scrollEnabled = YES;
}

- (void)evaluateMessageLinks {
    NSString *message = self.text;
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    NSArray *matches = [detector matchesInString:message
                                         options:0
                                           range:NSMakeRange(0, [message length])];
    if ([matches count] > 0) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSRange matchRange = [match range];
        NSString *url = [message substringWithRange:matchRange];
        if (![_postcardVC.currentPostcard.messageLink.originalUrl isEqualToString:url]) {
            _postcardVC.currentPostcard.messageLink = [[PCMessageLink alloc] init];
            [_postcardVC.currentPostcard.messageLink setMessageLinkURL:url];
            _postcardVC.linkAttachmentIndicator.hidden = NO;
        }
    } else if (_postcardVC.currentPostcard.messageLink == nil) {
        _postcardVC.linkAttachmentIndicator.hidden = YES;
    }
}

#pragma mark - Hashtags

- (NSArray *)getHashtagRanges {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\A|[\\s]{1,})#{1}([-A-Za-z0-9]{0,})"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error != nil) {
        BWLog(@"%@", error.description);
    }

    NSArray *matches = [regex matchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
    return matches;
}

- (NSArray *)getHashtags {
    NSArray *matches = [self getHashtagRanges];
    if (matches.count > 0) {
        NSMutableArray *stringArray = [NSMutableArray arrayWithCapacity:matches.count];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSString *word = [self.text substringWithRange:NSMakeRange(matchRange.location + 1, matchRange.length - 1)];
            [stringArray addObject:word];
        }
        return stringArray;
    } else {
        return nil;
    }
}

- (BOOL)evaluateHashtags {
    NSArray *matches = [self getHashtagRanges];
    if ([matches count] > 0) {
        NSRange currentRange = self.selectedRange;
        BOOL isEditing = NO;
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            if (currentRange.location >= matchRange.location && currentRange.location <= (matchRange.location + matchRange.length)) {
                self.editingWordRange = matchRange;
                isEditing = YES;
                break;
            }
        }
        if (isEditing) {
            if (_state != PCMessageTextViewStateHashtag) {
                _state = PCMessageTextViewStateHashtag;
                [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateHashtag];
            }
            NSString *word = [self.text substringWithRange:NSMakeRange(_editingWordRange.location, _editingWordRange.length)];
            word = [word stringByReplacingOccurrencesOfString:@"#" withString:@""];
            word = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [self.stateDelegate messageTextView:self currentSpecialWordText:word];
            return YES;
        }
    }
    return NO;
}

- (void)setTextForCurrentTag:(NSString *)text {
    NSString *replacement = [NSString stringWithFormat:@"%@#%@ ", (self.editingWordRange.location == 0) ? @"" : @" ", text];
    self.text = [self.text stringByReplacingCharactersInRange:self.editingWordRange withString:replacement];
    self.selectedRange = NSMakeRange(self.editingWordRange.location + replacement.length, 0);
    _state = PCMessageTextViewStateNormal;
    [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateNormal];
    AudioServicesPlaySystemSound(0x450);
}

#pragma mark - Mentions

- (NSArray *)getMentionRanges {
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\A|[\\s]{1,})@{1}([-A-Za-z0-9_]{0,})"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error != nil) {
        BWLog(@"%@", error.description);
    }

    NSArray *matches = [regex matchesInString:self.text options:0 range:NSMakeRange(0, [self.text length])];
    return matches;
}

- (BOOL)evaluateMentions {

    NSArray *matches = [self getMentionRanges];

    if ([matches count] > 0) {
        NSRange currentRange = self.selectedRange;
        BOOL isEditing = NO;
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];

            if (currentRange.location >= matchRange.location && currentRange.location <= (matchRange.location + matchRange.length)) {
                self.editingWordRange = matchRange;
                isEditing = YES;
                break;
            }
        }
        if (isEditing) {
            if (_state != PCMessageTextViewStateMention) {
                _state = PCMessageTextViewStateMention;
                [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateMention];
            }
            NSString *word = [self.text substringWithRange:NSMakeRange(_editingWordRange.location, _editingWordRange.length)];
            word = [word stringByReplacingOccurrencesOfString:@"@" withString:@""];
            word = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [self.stateDelegate messageTextView:self currentSpecialWordText:word];
            return YES;
        }
    }

    return NO;
}

- (void)setTextForCurrentMention:(NSString *)text {
    NSString *replacement = [NSString stringWithFormat:@"%@@%@ ", (self.editingWordRange.location == 0) ? @"" : @" ", text];
    self.text = [self.text stringByReplacingCharactersInRange:self.editingWordRange withString:replacement];
    self.selectedRange = NSMakeRange(self.editingWordRange.location + replacement.length, 0);
    _state = PCMessageTextViewStateNormal;
    [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateNormal];
    AudioServicesPlaySystemSound(0x450);
}

#pragma mark - UITextViewDelegate
- (void)textViewDidBeginEditing:(UITextView *)textView {
    [_postcardVC textViewDidBeginEditing:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@" "] || [text hasSuffix:@"\n"]) {
        _state = PCMessageTextViewStateNormal;
        [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateNormal];
        [self evaluateMessageLinks];
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self styleMessage];
    if( ![self evaluateHashtags] && ![self evaluateMentions] ){
        //no editing in progress
        [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateNormal];
    }
    [self evaluateMentions];
    [_postcardVC textViewDidChange:textView];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    [self evaluateMessageLinks];
    [_postcardVC textViewDidEndEditing:textView];
}

#pragma mark - UIKeyInput
- (void)deleteBackward {
    [super deleteBackward];
    if (self.text.length == 0) {
        _state = PCMessageTextViewStateNormal;
        [self.stateDelegate messageTextView:self enteringState:PCMessageTextViewStateNormal];
    }
}

@end