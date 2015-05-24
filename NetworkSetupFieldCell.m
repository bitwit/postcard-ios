//
// Created by Kyle Newsome on 2013-09-02.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "NetworkSetupFieldCell.h"


@implementation NetworkSetupFieldCell

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.textField.delegate = self;
    return self;
}

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value{
    [super setupWithParameters:params andValue:value];
    self.textField.delegate = self;
    self.textField.text = value;
}

-(void)prepareForReuse {
    self.fieldLabel.text = @"";
    self.textField.text = @"";
    self.textField.secureTextEntry = NO;
    self.textField.delegate = self;
}

-(id)getValue {
    return _textField.text;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if([self.delegate respondsToSelector:@selector(networkSetupCellDidBeginEditing:)]) {
        [self.delegate networkSetupCellDidBeginEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if([self.delegate respondsToSelector:@selector(networkSetupCellDidEndEditing:)]) {
        [self.delegate networkSetupCellDidEndEditing:self];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if([self.delegate respondsToSelector:@selector(networkSetupCellWillDismissKeyboard:)]) {
        [self.delegate networkSetupCellWillDismissKeyboard:self];
    }
    return YES;
}

@end