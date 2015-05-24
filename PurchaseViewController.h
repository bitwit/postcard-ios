//
//  PurchaseViewController.h
//  Postcard App
//
//  Created by Kyle Newsome on 2013-10-09.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PurchaseViewController : UIViewController

@property(nonatomic, weak) IBOutlet UITextView *twoNetworksIndicatorLabel;
@property(nonatomic, weak) IBOutlet UITextView *fiveNetworksIndicatorLabel;
@property(nonatomic, weak) IBOutlet UISlider *slider;

-(IBAction)back;
-(IBAction)sliderValueChanged;
-(IBAction)purchase;
-(IBAction)restore;

@end
