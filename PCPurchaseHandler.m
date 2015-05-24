//
// Created by Kyle Newsome on 1/11/2014.
// Copyright (c) 2014 Kyle Newsome. All rights reserved.
//


#import "PCPurchaseHandler.h"

@interface PCPurchaseHandler ()
@property(nonatomic, strong) NSArray *tiers;
@property(nonatomic, strong) IAPHelper *iapHelper;
@property(nonatomic, strong) NSArray *skProducts; //storekit products
@end

@implementation PCPurchaseHandler

+ (PCPurchaseHandler *)sharedInstance {
    static PCPurchaseHandler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PCPurchaseHandler alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    self.tiers = @[
            @{
                    @"title" : @"+2 Networks",
                    @"comparison" : @"Coffee",
                    @"price" : @"$0.99",
                    @"networks" : @2,
                    @"identifier" : @"2013001001"
            },

            @{
                    @"title" : @"+5 Networks",
                    @"comparison" : @"Latte",
                    @"price" : @"$2.99",
                    @"networks" : @5,
                    @"identifier" : @"2013001003"
            },
            @{
                    @"title" : @"Unlimited Networks",
                    @"comparison" : @"Sandwich",
                    @"price" : @"$4.99",
                    @"networks" : @-1,
                    @"identifier" : @"2013001005"
            },
    ];

    NSMutableSet *products = [NSMutableSet setWithCapacity:_tiers.count];
    for (NSDictionary *tier in _tiers) {
        [products addObject:tier[@"identifier"]];
    }
    self.iapHelper = [[IAPHelper alloc] initWithProductIdentifiers:products];
    [_iapHelper requestProductsWithCompletionHandler:^(BOOL success, NSArray *skProducts) {
        self.skProducts = skProducts;
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];

    return self;
}

- (void)purchaseProductAtIndex:(NSUInteger)idx {
    NSString *identifier = _tiers[idx][@"identifier"];
    for (SKProduct *product in _skProducts) {
        if ([product.productIdentifier isEqualToString:identifier]) {
            [_iapHelper buyProduct:product];
            break;
        }
    }
}

- (BOOL)hasPurchasedProductAtIndex:(NSUInteger)idx {
    NSString *identifier = _tiers[idx][@"identifier"];
    NSString *key = [NSString stringWithFormat:@"hasPurchased%@", identifier];
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

- (void)restorePurchases {
    [Flurry logEvent:@"Restore Purchase Pressed"];
    [_iapHelper restoreCompletedTransactions];
}

- (void)productPurchased:(NSNotification *)notification {
    @try {
        [Flurry logEvent:@"Product Purchase" withParameters:@{
                @"sku" : [NSString stringWithFormat:@"%@", notification.object]
        }];
    } @catch (NSException *e) {
        BWLog(@"Error logging purchase");
    }
    BWLog(@"%@: %@", NSStringFromClass([notification class]), notification.object);
    NSString *key = [NSString stringWithFormat:@"hasPurchased%@", notification.object];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PCPurchaseHandlerProductPurchased" object:nil];
}

- (NSInteger)maxAllowedNetworks {
    NSInteger networks = 3; //default allowed
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    for (NSDictionary *tier in _tiers) {
        NSString *key = [NSString stringWithFormat:@"hasPurchased%@", tier[@"identifier"]];
        BOOL purchased = [settings boolForKey:key];
        if (purchased) {
            NSInteger additionalNetworks = [tier[@"networks"] integerValue];
            if (additionalNetworks != -1) {
                networks += additionalNetworks;
            } else {
                return -1; //unlimited networks allowed
            }
        }
    }
    return networks;
}

@end