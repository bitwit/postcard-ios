//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupSegmentedControlCell.h"


@implementation NetworkSetupSegmentedControlCell

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value{
    [super setupWithParameters:params andValue:value];
    [_segmentedControl removeAllSegments];
    NSUInteger i = 0;
    for(NSString *option in [params valueForKey:@"dataSource"]){
        [_segmentedControl insertSegmentWithTitle:option atIndex:i animated:NO];
        i++;
    }
    _segmentedControl.selectedSegmentIndex = [(NSNumber *)value integerValue];
}

-(IBAction)segmentValueChanged:(id)sender{
    [self.delegate networkSetupCellValueDidChange:self];
}

-(id)getValue{
    //BWLog(@"Returning %@", @(_segmentedControl.selectedSegmentIndex));
    return @(_segmentedControl.selectedSegmentIndex);
}

@end