//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupListSelectionCell.h"


@interface NetworkSetupListSelectionCell()
@property(nonatomic, strong) NSArray *selectionSet;
@end

@implementation NetworkSetupListSelectionCell

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value{
    [super setupWithParameters:params andValue:value];
    [self setSelection:value];
}

-(void)setSelection:(NSArray *)selection{
    self.selectionSet = selection;
    self.textLabel.text = [NSString stringWithFormat:@"%d selected", _selectionSet.count];
}

-(id)getValue {
    return _selectionSet;
}

-(CGFloat)height {
    return 64.0f;
}

@end