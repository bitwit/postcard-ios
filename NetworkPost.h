//
//  NetworkPost.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-06-11.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NetworkPost : NSManagedObject

@property (nonatomic, retain) NSString * networkId;
@property (nonatomic, retain) NSString * postId;
@property (nonatomic, retain) NSManagedObject *postcard;

@end
