//
//  Tag.h
//  Postcard App
//
//  Created by Kyle Newsome on 11/27/2013.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tag : NSManagedObject

@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSString * value;

@end
