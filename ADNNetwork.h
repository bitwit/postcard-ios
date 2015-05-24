//
// Created by kylenewsome on 2012-12-22.
//

//


#import <Foundation/Foundation.h>
#import "Network.h"

#define ADN_BASE_URL @"https://alpha-api.app.net/"

@interface ADNNetwork : Network <UIAlertViewDelegate>
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;

- (void)initializeAdn;
@end