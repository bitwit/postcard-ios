//
// Created by kylenewsome on 2012-12-22.
//

#import "AccountsManager.h"

@interface AccountsManager ()

@end

@implementation AccountsManager {
}

static AccountsManager *sharedInstance;
+ (AccountsManager *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[AccountsManager alloc] init];
    }
    return sharedInstance;
}

-(id)init{
    self = [super init];
    if(self){
        self.accountStore = [[ACAccountStore alloc] init];
        NSArray *accounts = [self.accountStore accounts];
    }
    return self;
}

@end