//
// Created by kylenewsome on 2012-12-22.
//

#import <Foundation/Foundation.h>
#import "NetworksManager.h"
#import "NetworkSetupManager.h"
//#import "PCDataDelegate.h"


@class NetworkSetupManager;

@interface Network : NSObject <NSCoding>

@property(nonatomic) Networks tag;
@property(nonatomic, strong) NSString *name;
@property(nonatomic) BOOL isLinked;
@property(nonatomic, strong) NSString *UUID;
@property(nonatomic, weak) NetworkSetupManager *setupManager;
@property(copy) void (^feedRequestHandler)(BOOL, NSArray *);


//network features
@property(nonatomic) BOOL usesTags;
@property(nonatomic) int charLimit;
@property(nonatomic) BOOL acceptsImages;
@property(nonatomic) BOOL acceptsVideo;
@property(nonatomic) BOOL canHostContent;

-(void)willDelete;

//called for setting up permissions
- (void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager;

//called for getting settings properties
- (NSArray *)settingFields;

//determines whether the current social activity will work on this network
-(NSDictionary *)confirmPostActivityEligibility:(PCSocialActivity *)activity;

//how to post to this network
- (void)postUpdate:(PCSocialActivity *)activity;

//feed request
- (void)requestFeedWithParameters:(NSDictionary *)params completion:(void (^)(BOOL success, NSArray *messages))handler;

//
- (void)accountSelected:(NSUInteger)index;


@end