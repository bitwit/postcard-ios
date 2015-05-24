//
//  TagSuggestionTableViewCell.m
//  Postcard App
//
//  Created by Kyle Newsome on 11/28/2013.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "TagSuggestionTableViewCell.h"

@implementation TagSuggestionTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {

    assert([aDecoder isKindOfClass:[NSCoder class]]);

    self = [super initWithCoder:aDecoder];

    if (self) {
        UIView *bgView = [[UIView alloc] initWithFrame:self.frame];
        bgView.backgroundColor = [PCColorPalette lightBlueColor];
        self.selectedBackgroundView = bgView;
        CGFloat k90DegreesClockwiseAngle = (CGFloat) (90 * M_PI / 180.0);
        self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, k90DegreesClockwiseAngle);
    }

    return self;
}


@end
