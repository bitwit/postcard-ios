//
//  Person.h
//  Postcard App
//
//  Created by Kyle Newsome on 12/2/2013.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * networkId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * avatarUrl;

@end
