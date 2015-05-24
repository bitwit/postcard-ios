//
// Created by Kyle Newsome on 1/18/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol BWTutorialSubview <NSObject>
@property(nonatomic) NSRange visibleStageRange;
@end

@interface BWTutorialView : UIView

- (void)showFromIndex:(NSUInteger)index;

- (void)show;

- (void)dismiss;

- (IBAction)prev;

- (IBAction)next;

@end