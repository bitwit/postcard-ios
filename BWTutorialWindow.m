//
// Created by Kyle Newsome on 1/19/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "BWTutorialWindow.h"
#import "BWTutorialTouchableCutOutView.h"

@implementation BWTutorialWindow


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // See if the hit is anywhere in our view hierarchy
    UIView *hitTestResult = [super hitTest:point withEvent:event];
    // ABKSlideupHostOverlay view covers the pass-through touch area.  It's recognized
    // by class, here, because the window doesn't have a pointer to the actual view object.
    if ([hitTestResult isKindOfClass:[BWTutorialTouchableCutOutView class]]) {
        // Returning nil means this window's hierachy doesn't handle this event. Consequently,
        // the event will be passed to the host window.
        return nil;
    }

    //BWLog(@"hit result %@", hitTestResult);

    return hitTestResult;
}

@end