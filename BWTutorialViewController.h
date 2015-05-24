//
// Created by Kyle Newsome on 1/19/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>


@class BWTutorialView;
@class BWTutorialWindow;

@interface BWTutorialViewController : UIViewController

@property (nonatomic, strong) UIWindow *previousWindow;
@property (nonatomic, strong) BWTutorialWindow *window;

+(instancetype)sharedInstance;

- (void)showTutorialView:(BWTutorialView *)tutorialView completion:(void (^)(void))completionHandler;

- (void)dismissTutorialView:(BWTutorialView *)tutorialView completion:(void (^)(void))completionHandler;
@end