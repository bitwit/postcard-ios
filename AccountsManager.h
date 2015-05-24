//
// Created by kylenewsome on 2012-12-22.
//

#import <Foundation/Foundation.h>

@interface AccountsManager : NSObject

@property(nonatomic, strong) ACAccountStore *accountStore;

+(AccountsManager *)sharedInstance;

@end