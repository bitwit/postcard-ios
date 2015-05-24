//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCTaggingSystemView.h"

@interface PCTaggingSystemView ()

@end

@implementation PCTaggingSystemView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initializeView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initializeView];
    }
    return self;
}

- (void)initializeView {
    self.showsHorizontalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = YES;
    self.tagTextFields = [[NSMutableArray alloc] init];
    [self addNewField];
}

- (void)addNewField {
    PCTagTextField *field = [[PCTagTextField alloc] initWithFrame:CGRectMake((float) fmax(320.0f, (self.contentSize.width + 320.0f)), 0, 60, 32)];
    field.layer.masksToBounds = YES;
    field.layer.cornerRadius = 6.0f;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.returnKeyType = UIReturnKeyNext;
    field.delegate = self;
    field.pcDelegate = self;

    field.backgroundColor = [PCColorPalette lightOrangeColor];
    field.tintColor = [UIColor whiteColor];
    field.textColor = [PCColorPalette lightBlueColor];
    field.textAlignment = NSTextAlignmentCenter;
    field.placeholder = @"tag me";

    [_tagTextFields addObject:field];
    [self addSubview:field];
    [self calculateContentSizeAndPositions];
}

- (void)setTextForCurrentTag:(NSString *)text {
    for (UITextField *textField in _tagTextFields) {
        if (textField.isFirstResponder) {
            [textField setText:text];
            if ([self isTextFieldLastOne:textField]) {
                [self addNewField];
                [(UITextField *) _tagTextFields.lastObject becomeFirstResponder];
            } else {
                [(UITextField *) _tagTextFields[(NSUInteger) ([_tagTextFields indexOfObject:textField] + 1)] becomeFirstResponder];
            }
            [self resizeFrameForTextField:textField];
            [self calculateContentSizeAndPositions];
        }
    }
}

- (NSArray *)arrayOfTags {
    if (_tagTextFields.count == 1 && [[(UITextField *) _tagTextFields[0] text] isEqualToString:@""]) {
        return nil;
    }
    NSMutableArray *tags = [NSMutableArray array];
    for (UITextField *textField in _tagTextFields) {
        [tags addObject:textField.text];
    }
    return tags;
}

- (NSString *)commaSeparatedTags {
    if (_tagTextFields.count == 1 && [[(UITextField *) _tagTextFields[0] text] isEqualToString:@""]) {
        return nil;
    }
    return [self.arrayOfTags componentsJoinedByString:@","];
}

- (void)reset {
    [_tagTextFields removeAllObjects];
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self addNewField];
}

- (BOOL)resignFirstResponder {
    for (UITextField *textField in _tagTextFields) {
        if (textField.isFirstResponder) {
            return [textField resignFirstResponder];
        }
    }
    return NO;
}

- (BOOL)isTextFieldLastOne:(UITextField *)textField {
    return ([_tagTextFields indexOfObject:textField] == _tagTextFields.count - 1);
}

- (void)calculateContentSizeAndPositions {
    [UIView animateWithDuration:0.38f
                          delay:0.0f
         usingSpringWithDamping:0.66f
          initialSpringVelocity:0.0f
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         CGFloat xPosition = 0.0f; //first center location
                         CGFloat marginRight = 10.0f;
                         for (UITextField *textField in _tagTextFields) {
                             textField.frame = CGRectMake(xPosition, 0, CGRectGetWidth(textField.frame), CGRectGetHeight(textField.frame));
                             xPosition += CGRectGetWidth(textField.frame) + marginRight;
                         }
                         self.contentSize = CGSizeMake(xPosition + 60, 32);
                         if ([_tagTextFields.lastObject isFirstResponder]) {
                             [self setContentOffset:CGPointMake(fmaxf(xPosition - CGRectGetWidth(self.frame), 0), 0) animated:YES];
                         }
                     } completion:nil];
}

- (void)resizeFrameForTextField:(UITextField *)textField {
    [textField sizeToFit];
    textField.frame = CGRectMake(textField.frame.origin.x,
            textField.frame.origin.y,
            CGRectGetWidth(textField.frame) + 16,
            32);
}

- (void)runClosingEvaluationsForTextField:(UITextField *)textField {
    if ([textField.text isEqualToString:@""]) {
        if (_tagTextFields.count > 1) {
            [_tagTextFields removeObject:textField];
            [textField removeFromSuperview];
        } else {
            textField.placeholder = @"tag me";
            [self resizeFrameForTextField:textField];
        }
        [self calculateContentSizeAndPositions];
    }
}

#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.taggingDelegate taggingSystemDidBeginEditingTagField:self];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self runClosingEvaluationsForTextField:textField];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    textField.placeholder = nil;
    [self resizeFrameForTextField:textField];
    [self calculateContentSizeAndPositions];
    [self.taggingDelegate taggingSystem:self textForCurrentTag:[textField.text stringByReplacingCharactersInRange:range withString:string]];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self resizeFrameForTextField:textField];
    [self calculateContentSizeAndPositions];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self isTextFieldLastOne:textField]) {
        [self addNewField];
        [(UITextField *) _tagTextFields.lastObject becomeFirstResponder];
    } else {
        [(UITextField *) _tagTextFields[(NSUInteger) ([_tagTextFields indexOfObject:textField] + 1)] becomeFirstResponder];
    }
    [self runClosingEvaluationsForTextField:textField];
    return NO;
}

#pragma mark - PCTagTextFieldDelegate

- (void)textFieldWantsDelete:(PCTagTextField *)textField {
    BWLog(@"clearing empty field");
    //if empty, let user backspace into previous tag
    NSUInteger index = [_tagTextFields indexOfObject:textField];
    if (index > 0) {
        [(UITextField *) _tagTextFields[index - 1] becomeFirstResponder];
    }
}

@end