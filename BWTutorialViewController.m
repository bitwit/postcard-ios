//
// Created by Kyle Newsome on 1/19/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "BWTutorialViewController.h"
#import "BWTutorialWindow.h"
#import "BWTutorialView.h"


@interface BWTutorialViewController ()
@property(nonatomic, strong) UIView *rootView;
@property(nonatomic, strong) NSMutableArray *tutorialViews;
@end

@implementation BWTutorialViewController

+ (instancetype)sharedInstance {
    static BWTutorialViewController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BWTutorialViewController alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    self.tutorialViews = NSMutableArray.new;
    BWLog(@"Tutorial VC init");
    return self;
}

- (void)initializeWindow {
    self.previousWindow = [[UIApplication sharedApplication] keyWindow];

    self.window = [[BWTutorialWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self;
    self.window.windowLevel = UIWindowLevelAlert;

    self.rootView = [[UIView alloc] initWithFrame:self.window.bounds];
    [self.window addSubview:self.rootView];

    BWLog(@"tutorial root view -> %@", _rootView);
}

- (void)showTutorialView:(BWTutorialView *)tutorialView completion:(void (^)(void))completionHandler {
    BWLog(@"");
    if (![_tutorialViews containsObject:tutorialView]) {
        [self.tutorialViews addObject:tutorialView];
        if (_tutorialViews.count > 1) {
            return;
        }
    }

    tutorialView.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2,[UIScreen mainScreen].bounds.size.height/2);

    if ([[UIApplication sharedApplication] keyWindow] != self.window) {
        [self initializeWindow];
        [self.window makeKeyAndVisible];
        [self.window bringSubviewToFront:self.rootView];
    }

    [self.rootView addSubview:tutorialView];
    tutorialView.alpha = 0.0f;
    [UIView animateWithDuration:0.36f animations:^{
        tutorialView.alpha = 0.9f;
    }                completion:^(BOOL finished) {
        if (completionHandler != nil) {
            completionHandler();
        }
    }];

}

- (void)dismissTutorialView:(BWTutorialView *)tutorialView completion:(void (^)(void))completionHandler {

    [UIView animateWithDuration:0.36f animations:^{
        tutorialView.alpha = 0.0f;
    }                completion:^(BOOL finished) {
        [tutorialView removeFromSuperview];
        [self.tutorialViews removeObject:tutorialView];
        [self.previousWindow makeKeyAndVisible];
        self.window = nil;
        if (completionHandler != nil) {
            completionHandler();
        }
        if (_tutorialViews.count != 0) {
            BWLog(@"Showing next tutorial view");
            [self showTutorialView:_tutorialViews.firstObject completion:nil];
        }
    }];
}


@end