//
// Created by Kyle Newsome on 2013-07-20.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

//


#import <Foundation/Foundation.h>
#import "Network.h"


@interface CustomNetwork : Network
@property(nonatomic, strong) NSString *siteUrl;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) NSString *password;
@end