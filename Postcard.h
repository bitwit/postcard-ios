//
//  Postcard.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-06-11.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NetworkPost;

@interface Postcard : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * video;
@property (nonatomic, retain) NSString * mediaMimeType;
@property (nonatomic, retain) NSSet * networkPosts;

@end

@interface Postcard (CoreDataGeneratedAccessors)

- (void)addNetworkPostsObject:(NetworkPost *)value;
- (void)removeNetworkPostsObject:(NetworkPost *)value;
- (void)addNetworkPosts:(NSSet *)values;
- (void)removeNetworkPosts:(NSSet *)values;

@end
