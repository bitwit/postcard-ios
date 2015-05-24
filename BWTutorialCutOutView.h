//
// Created by Kyle Newsome on 1/21/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "BWTutorialView.h"

@interface BWTutorialCutOutView : UIView <BWTutorialSubview>
@property(nonatomic) NSRange visibleStageRange;
@end