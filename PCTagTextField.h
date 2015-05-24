//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>

@class PCTagTextField;

@protocol PCTagTextFieldDelegate <NSObject>
- (void)textFieldWantsDelete:(PCTagTextField *)textField;
@end

@interface PCTagTextField : UITextField <UIKeyInput>

@property (nonatomic, weak) id<PCTagTextFieldDelegate> pcDelegate;

@end