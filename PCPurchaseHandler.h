//
// Created by Kyle Newsome on 1/11/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "IAPHelper.h"


@interface PCPurchaseHandler : NSObject

+ (PCPurchaseHandler *)sharedInstance;

- (void)purchaseProductAtIndex:(NSUInteger)idx;
- (BOOL)hasPurchasedProductAtIndex:(NSUInteger)idx;
- (void)restorePurchases;

- (NSInteger)maxAllowedNetworks;
@end