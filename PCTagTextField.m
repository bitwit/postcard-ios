//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCTagTextField.h"

@interface PCTagTextField()
@property(nonatomic) NSUInteger lastLength;
@end

@implementation PCTagTextField

- (void)deleteBackward {
    _lastLength = self.text.length;
    [super deleteBackward];
    if([self.text isEqualToString:@""] && _lastLength == 0 && [self.pcDelegate respondsToSelector:@selector(textFieldWantsDelete:)]){
         [self.pcDelegate textFieldWantsDelete:self];
    }
}

@end