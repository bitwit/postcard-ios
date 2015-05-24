//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "NetworkSetupCell.h"

@interface NetworkSetupSegmentedControlCell : NetworkSetupCell

@property(nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)segmentValueChanged:(id)sender;
@end