//
// Created by Kyle Newsome on 1/19/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface BWTutorialWindow : UIWindow

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event;

@end