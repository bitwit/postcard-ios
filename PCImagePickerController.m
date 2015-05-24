//
// Created by Kyle Newsome on 2013-09-24.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PCImagePickerController.h"


@implementation PCImagePickerController

-(id)init{
    if( (self = [super init]) ){
        self.navigationBar.translucent = NO;
        self.navigationBar.tintColor = [UIColor whiteColor];
        self.navigationBar.barTintColor = [PCColorPalette mediumBlueColor];
        self.navigationBar.titleTextAttributes = @{
                NSForegroundColorAttributeName : [UIColor whiteColor]
        };
    }
    return self;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end