//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCToolbarView.h"

@implementation PCToolbarView

- (void)showMainOptions {
    [UIView animateWithDuration:0.46f animations:^{
        self.mainView.alpha = 1.0f;
        self.suggestionSystemView.alpha = 0.0f;
    }];
}

- (void)hideMainOptions {
    [UIView animateWithDuration:0.46f animations:^{
        self.mainView.alpha = 0.0f;
        self.suggestionSystemView.alpha = 1.0f;
    }];
}

@end