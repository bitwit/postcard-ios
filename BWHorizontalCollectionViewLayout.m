//
// Created by Kyle Newsome on 15-02-09.
// Copyright (c) 2015 Kyle Newsome. All rights reserved.
//

#import "BWHorizontalCollectionViewLayout.h"


@implementation BWHorizontalCollectionViewLayout {

}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if ((self = [super initWithCoder:aDecoder])) {
        self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        self.minimumLineSpacing = 0.0f;
    }
    return self;
}

@end