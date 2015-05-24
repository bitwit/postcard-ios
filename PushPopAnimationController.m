//
//  BLAdTransitionController.m
//  prototype
//
//  Created by César Pinto Castillo on 12/06/13.
//  Copyright (c) 2013 Blocket. All rights reserved.
//

#import "PushPopAnimationController.h"

#define PUSH_POP_BG_PARALLAX_DISTANCE 140.0f

@implementation PushPopAnimationController

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {

    // 1. the usual stuff ...
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    [containerView addSubview:toVC.view];

    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    CGFloat RTLmodifier = (_isRightToLeftMode) ? -1.0f : 1.0f;

    UIView *fromViewSnap = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    fromViewSnap.frame = fromVC.view.frame;
    [containerView addSubview:fromViewSnap];
    fromVC.view.hidden = YES;

    if (_reverse) {
       // [self setupShadowForView:toVC.view];
        [containerView bringSubviewToFront:toVC.view];
        toVC.view.frame = CGRectOffset(finalFrame, RTLmodifier * -screenBounds.size.width, 0);
        fromViewSnap.alpha = 1.0f;
        CGRect offsetFrame = CGRectOffset(finalFrame, RTLmodifier * PUSH_POP_BG_PARALLAX_DISTANCE, 0);
       // [toVC.view.layer setShadowOpacity:0.0f];
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            toVC.view.frame = finalFrame;
            fromViewSnap.frame = offsetFrame;
            fromViewSnap.alpha = 0.10f;
        //    [toVC.view.layer setShadowOpacity:0.80f];
        }                completion:^(BOOL finished) {
            [fromViewSnap removeFromSuperview];
            fromVC.view.hidden = NO;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else {
       // [self setupShadowForView:fromViewSnap];
        [containerView sendSubviewToBack:toVC.view];
        toVC.view.frame = CGRectOffset(finalFrame, RTLmodifier * PUSH_POP_BG_PARALLAX_DISTANCE, 0);
        toVC.view.alpha = 0.10f;
        CGRect fromOffsetFrame = CGRectOffset(finalFrame, RTLmodifier * -screenBounds.size.width, 0);
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            toVC.view.frame = finalFrame;
            toVC.view.alpha = 1.0f;
            fromViewSnap.frame = fromOffsetFrame;
       //     [fromViewSnap.layer setShadowOpacity:0.0f];
        }                completion:^(BOOL finished) {
            [fromViewSnap removeFromSuperview];
            fromVC.view.hidden = NO;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }

}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.32f;
}

- (void)setupShadowForView:(UIView *)view {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.frame cornerRadius:10];
    CALayer *viewLayer = view.layer;
    [viewLayer setShadowColor:[UIColor blackColor].CGColor];
    [viewLayer setShadowOpacity:0.8f];
    [viewLayer setShadowRadius:6.0f];
    [viewLayer setShadowPath:[path CGPath]];
}

/*

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    [containerView addSubview:toVC.view];

    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];

    NSTimeInterval duration = [self transitionDuration:transitionContext];
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    CGFloat RTLmodifier = (_isRightToLeftMode) ? -1.0f : 1.0f;

    UIView *fromViewSnap = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    fromViewSnap.frame = fromVC.view.frame;
    [self setupShadowForView:fromViewSnap];
    [containerView addSubview:fromViewSnap];
    [containerView sendSubviewToBack:fromViewSnap];
    fromVC.view.hidden = YES;

    if (_reverse) {
        [containerView sendSubviewToBack:toVC.view];
        CGRect offsetFrame = CGRectOffset(finalFrame, RTLmodifier * screenBounds.size.width, 0);
        toVC.view.frame = CGRectOffset(finalFrame, RTLmodifier * -PUSH_POP_BG_PARALLAX_DISTANCE, 0);
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            toVC.view.frame = finalFrame;
            fromViewSnap.frame = offsetFrame;
        }                completion:^(BOOL finished) {
            [fromViewSnap removeFromSuperview];
            fromVC.view.hidden = NO;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    } else {
        toVC.view.frame = CGRectOffset(finalFrame, RTLmodifier * screenBounds.size.width, 0);
        CGRect fromOffsetFrame = CGRectOffset(finalFrame, RTLmodifier * -PUSH_POP_BG_PARALLAX_DISTANCE, 0);
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
            toVC.view.frame = finalFrame;
            fromViewSnap.frame = fromOffsetFrame;
        }                completion:^(BOOL finished) {
            [fromViewSnap removeFromSuperview];
            fromVC.view.hidden = NO;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}



* */


@end
