//
//  SwipeINteractionController.m
//  ILoveCatz
//
//  Created by Colin Eberhardt on 22/08/2013.
//  Copyright (c) 2013 com.razeware. All rights reserved.
//

#import "EdgeSwipeInteractionController.h"

#define SWIPE_VELOCITY_THRESHOLD 800.0f

@implementation EdgeSwipeInteractionController {
    BOOL _shouldCompleteTransition;
    UINavigationController *_navigationController;
    UIView *_wiredView;
    UIScreenEdgePanGestureRecognizer *_wiredGestureRecognizer;
    CGFloat _startingX;
}

- (void)dealloc {
    BWLog(@"InteractionController DEALLOC");
}

- (void)wireToViewController:(UIViewController *)viewController {
    _navigationController = viewController.navigationController;
    [self prepareGestureRecognizerInView:viewController.view];
}

- (void)prepareGestureRecognizerInView:(UIView *)view {
    _wiredView = view;
    _wiredGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    _wiredGestureRecognizer.edges = _isRightToLeftMode ? UIRectEdgeRight : UIRectEdgeLeft;
    [view addGestureRecognizer:_wiredGestureRecognizer];
}

- (CGFloat)completionSpeed {
    return 1 - self.percentComplete;
}

- (void)handleGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
    CGPoint location = [gestureRecognizer locationInView:gestureRecognizer.view.superview];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            // 1. Start an interactive transition!
            self.interactionInProgress = YES;
            _startingX = location.x;
            [_navigationController popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged: {
            // 2. compute the current position
            CGFloat translationX = translation.x;
            if (_startingX >= 180 && translationX > 0) {
                translationX = 0;
            } else if (_startingX <= 140 && translationX < 0) {
                translationX = 0;
            }
            CGFloat fraction = ((CGFloat) fabs(translationX) / 320.0f);
            fraction = fminf(fmaxf(fraction, 0.0f), 1.0f);
            // 3. should we complete?
            _shouldCompleteTransition = (fraction > 0.5f);
            // 4. update the animation controller
            [self updateInteractiveTransition:fraction];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.interactionInProgress = NO;
            CGPoint velocity = [gestureRecognizer velocityInView:_wiredView];
            BOOL shouldCancel = !_shouldCompleteTransition;
            if (gestureRecognizer.state == UIGestureRecognizerStateCancelled) shouldCancel = YES;

            if (velocity.x <= -SWIPE_VELOCITY_THRESHOLD) shouldCancel = (_isRightToLeftMode != YES);
            if (velocity.x >= SWIPE_VELOCITY_THRESHOLD) shouldCancel = (_isRightToLeftMode != NO);

            if (shouldCancel) {
                [self cancelInteractiveTransition];
            }
            else {
                [self finishInteractiveTransition];
            }
        }
            break;
        default:
            break;
    }
}

@end