//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupSwitchCell.h"


@implementation NetworkSetupSwitchCell

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value {
    [super setupWithParameters:params andValue:value];
    [_fieldSwitch setOn:[(NSNumber *)value boolValue] animated:NO];
}

-(id)getValue{
    return @(_fieldSwitch.isOn);
}

-(CGFloat)height{
    return 64.0f;
}

@end