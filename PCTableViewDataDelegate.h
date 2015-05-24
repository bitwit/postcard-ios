//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PCSocialActivity.h"

@class PCViewController;

@interface PCTableViewDataDelegate : NSObject <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, weak) UITableView *tableView;
@property(nonatomic, weak) PCViewController *viewController;

-(id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController;

- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight;

@end

#import "PCViewController.h"