//
// Created by Kyle Newsome on 1/8/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NetworkSetupCell.h"


@interface NetworkSetupURLButtonCell : NetworkSetupCell

@property(nonatomic, strong) NSString *urlString;
@property(nonatomic, weak) IBOutlet UIButton *visitButton;

-(IBAction)visitURL;

@end