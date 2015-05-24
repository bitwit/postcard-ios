//
// Created by kylenewsome on 2012-12-22.
//

#import "Network.h"
#import "NetworkSetupManager.h"

#import "PCSocialActivity.h"
#import "PDKeychainBindingsController.h"

@interface Network ()

@end

@implementation Network

-(id)init{
    if((self = [super init])){
        self.usesTags = NO;
        self.charLimit = 0;
        self.acceptsImages = NO;
        self.acceptsVideo = NO;
        self.canHostContent = YES;
        self.UUID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

#pragma mark NSCoder (Archiving)
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.isLinked forKey:@"isLinked"];
    [coder encodeObject:self.UUID forKey:@"UUID"];
}

- (id)initWithCoder:(NSCoder *)coder {
   // BWLog(@"%@ INIT", NSStringFromClass(self.class));
    self = [self init];
    if (self) {
        [self setIsLinked:[coder decodeBoolForKey:@"isLinked"]];
        [self setUUID:[coder decodeObjectForKey:@"UUID"]];
    }
    return self;
}

-(void)willDelete{

}

-(void)dealloc{
   // BWLog(@"%@ DEALLOCATING", NSStringFromClass(self.class));
}

-(void)getAccessWithSetupManager:(NetworkSetupManager *)setupManager{
    self.setupManager = setupManager;
}

-(NSArray *)settingFields{
    return nil;
}

-(NSDictionary *)confirmPostActivityEligibility:(PCSocialActivity *)activity{
    NSInteger length = 0;
    length += [activity.message length];
    length += (activity.messageMedia != nil) ? 23 : 0;

    //video posting eligibility issues
    if(activity.messageMedia.videoData != nil && !_acceptsVideo) {
        return @{
                @"success": @NO,
                @"reason": @"Can't post video"
        };
    }

    //image posting eligibility issues
    if(activity.messageMedia.imageData != nil && !_acceptsImages) {
        return @{
                @"success": @NO,
                @"reason": @"Can't post images"
        };
    }

    //character limit issues
    if (_charLimit != 0 && length > _charLimit) {
        return @{
                @"success": @NO,
                @"reason": [NSString stringWithFormat:@"Can't post messages over %d characters", _charLimit]
        };
    }

    return @{
            @"success": @YES
    };
}

- (void)postUpdate:(PCSocialActivity *)activity {

    if (!self.isLinked) {
        @throw [NSException exceptionWithName:@"Posting to unlinked Network" reason:@"trying to post on a netowrk that isnt linked" userInfo:nil];
    }

}

- (void)requestFeedWithParameters:(NSDictionary *)params completion:(void (^)(BOOL success, NSArray *messages))handler {
    BWLog(@"");
    self.feedRequestHandler = handler;
}

- (void)accountSelected:(NSUInteger)index {

}


@end