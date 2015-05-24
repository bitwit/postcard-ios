//
// Created by Kyle Newsome on 1/18/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "BWTutorialView.h"
#import "BWTutorialViewController.h"
#import "BWTutorialTouchableCutOutView.h"


@interface BWTutorialView ()
@property(nonatomic, strong) NSMutableArray *bezierPaths;
@property(nonatomic) BOOL isPresenting;
@property(nonatomic) BOOL isSetup;
@property(nonatomic, strong) NSMutableArray *viewStages;
@property(nonatomic, strong) NSMutableArray *multiStageViews;
@property(nonatomic) NSUInteger currentIndex;
@property(nonatomic, weak) UIView *originalContainer;

@property(nonatomic, weak) NSLayoutConstraint *heightConstraint;
@property(nonatomic, weak) NSLayoutConstraint *widthConstraint;

@end

@implementation BWTutorialView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    self.opaque = NO;
    self.hidden = YES;
    self.viewStages = NSMutableArray.new;
    self.multiStageViews = NSMutableArray.new;
    self.bezierPaths = NSMutableArray.new;
    return self;
}

- (void)setupTutorialView {
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1
                                                                         constant:[UIScreen mainScreen].bounds.size.height];

    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:[UIScreen mainScreen].bounds.size.width];
    self.heightConstraint = heightConstraint;
    self.widthConstraint = widthConstraint;
    [self addConstraints:@[heightConstraint, widthConstraint]];

    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"tag" ascending:YES];
    NSArray *finalArray = [self.subviews sortedArrayUsingDescriptors:[NSArray arrayWithObjects:descriptor, nil]];

    NSInteger currentStageTag = -1;
    NSMutableArray *stageViews = nil;
    for (UIView *view in finalArray) {
        if (view.tag == -1) {
            [_multiStageViews addObject:view];
            [view removeFromSuperview];
        } else {
            if (view.tag != currentStageTag) {
                if (stageViews != nil) {
                    [_viewStages addObject:stageViews];
                }
                currentStageTag = view.tag;
                stageViews = NSMutableArray.new;
            }
            [stageViews addObject:view];
            [view removeFromSuperview];
        }
    }

    if (stageViews != nil) {
        [_viewStages addObject:stageViews];
    }

    self.isSetup = YES;
}

- (void)showFromIndex:(NSUInteger)index {
    if (!_isSetup) {
        [self setupTutorialView];
    }

    _currentIndex = index;
    NSArray *stage = _viewStages[_currentIndex];
    [_bezierPaths removeAllObjects];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    for (UIView *view in [self multiStageViews]) {
        if ([view isKindOfClass:BWTutorialCutOutView.class]) {
            NSRange range = [(BWTutorialCutOutView *) view visibleStageRange];
            if (range.length != 0 && !NSLocationInRange(index, range)) {
                //this is a view we want to show for a specific period
                //and it's out of bounds
                continue;
            }
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:view.frame];
            [_bezierPaths addObject:bezierPath];
            [self addSubview:view];
        } else {
            [self addSubview:view];
        }
    }

    for (UIView *view in stage) {
        if ([view isKindOfClass:BWTutorialCutOutView.class]) {
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:view.frame];
            [_bezierPaths addObject:bezierPath];
        }
        [self addSubview:view];
    }

    if (!_isPresenting) {
        self.hidden = NO;
        self.isPresenting = YES;
        self.originalContainer = self.superview;
        [self removeFromSuperview];
        [self setNeedsDisplay];
        [[BWTutorialViewController sharedInstance] showTutorialView:self completion:nil];
    } else {
        [UIView transitionWithView:self
                          duration:0.33f
                           options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            [self setNeedsDisplay];
        }               completion:nil];
    }

}

- (void)show {
    [self showFromIndex:0];
}

- (void)dismiss {
    if (_isPresenting) {
        [[BWTutorialViewController sharedInstance] dismissTutorialView:self completion:^{
            self.isPresenting = NO;
            self.hidden = YES;
            //[self removeConstraints:@[_heightConstraint, _widthConstraint]];
            [self.originalContainer addSubview:self];
        }];
    }
}

- (void)drawRect:(CGRect)rect {
    [[UIColor blackColor] set];
    UIRectFill(rect);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(ctx, kCGBlendModeDestinationOut);
    for (UIBezierPath *path in _bezierPaths) {
        [path fill];
    }
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
}

- (IBAction)prev {
    if (_currentIndex > 0) {
        [self showFromIndex:_currentIndex - 1];
    }
}

- (IBAction)next {
    if (_currentIndex < _viewStages.count - 1) {
        [self showFromIndex:_currentIndex + 1];
    }
}

@end