//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "NetworkSetupCell.h"
#import "PCColorPalette.h"


@implementation NetworkSetupCell

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
    bgView.backgroundColor = [PCColorPalette lightOrangeColor];
    self.selectedBackgroundView = bgView;
    return self;
}

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value{
    //BWLog(@" Setting %@ with %@", NSStringFromClass([self class]), value);
}

- (CGFloat)height {
    if(_isHidingContent) return 0;
    return [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1.0f;
}

-(id)getValue{
    return nil;
}

@end