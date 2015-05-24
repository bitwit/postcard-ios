//
//  PurchaseViewController.m
//  Postcard App
//
//  Created by Kyle Newsome on 2013-10-09.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "PurchaseViewController.h"
#import "IAPHelper.h"
#import "PCPurchaseHandler.h"
#import "PCViewController.h"

@interface PurchaseViewController ()
@property(nonatomic, weak) PCPurchaseHandler *purchaseHandler;
@end

@implementation PurchaseViewController

- (void)viewDidLoad {
    self.purchaseHandler = [PCPurchaseHandler sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased) name:@"PCPurchaseHandlerProductPurchased" object:nil];

    NSInteger maxNetworks = _purchaseHandler.maxAllowedNetworks;

    if ([_purchaseHandler hasPurchasedProductAtIndex:0]) {
        _twoNetworksIndicatorLabel.text = @"Purchased";
    }  else {
        NSString *title = [NSString stringWithFormat:@"+2 Networks \n (%d Total)", 2 + maxNetworks];
        _twoNetworksIndicatorLabel.text = title;
    }

    if ([_purchaseHandler hasPurchasedProductAtIndex:1]) {
        _fiveNetworksIndicatorLabel.text = @"Purchased";
    } else {
        NSString *title = [NSString stringWithFormat:@"+5 Networks \n (%d Total)", 5 + maxNetworks];
        _fiveNetworksIndicatorLabel.text = title;
    }

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc {
    BWLog(@"Deallocating");
}

- (IBAction)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)sliderValueChanged {
    NSUInteger index = (NSUInteger) roundf(_slider.value);
    [_slider setValue:index animated:NO];
}

- (IBAction)purchase {
    NSUInteger index = (NSUInteger) roundf(_slider.value);
    [_purchaseHandler purchaseProductAtIndex:index];
}

-(IBAction)restore{
   [_purchaseHandler restorePurchases];
}

- (void)productPurchased {
    PCViewController *pcViewController = self.navigationController.viewControllers[0];
    [pcViewController.settingsTableDelegate recalculateCellInfo];
    [pcViewController.tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}


@end
