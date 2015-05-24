//
//  ConnectedNetwork.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-08-12.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ConnectedNetwork : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSNumber * isEnabled;
@property (nonatomic, retain) NSNumber * isHost;
@property (nonatomic, retain) NSDate * lastActivated;
@property (nonatomic, retain) NSDate * lastDeactivated;
@property (nonatomic, retain) NSString * networkId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) id instance;

@end
