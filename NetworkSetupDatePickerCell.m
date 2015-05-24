//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupDatePickerCell.h"


@implementation NetworkSetupDatePickerCell

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value {
    [super setupWithParameters:params andValue:value];
    _datePicker.minimumDate = [[ NSDate alloc ] initWithTimeIntervalSinceNow: (NSTimeInterval) (60 * 5) ];
    if (value != nil) {
        _datePicker.date = value;
    }
}

-(id)getValue {
    return _datePicker.date;
}

-(CGFloat)height {
    if(self.isHidingContent) {
        return 0.0f;
    } else {
        return 216.0f;
    }
}

@end