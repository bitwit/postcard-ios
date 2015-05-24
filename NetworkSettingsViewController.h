//
//  NetworkSettingsViewController.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-17.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkSetupCell.h"

@class ConnectedNetwork;

@interface NetworkSettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NetworkSetupCellDelegate>

@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, weak) IBOutlet BWTutorialView *tutorialView;

- (void)setNetworkForSettings:(ConnectedNetwork *)network;

- (IBAction)back;

- (IBAction)dismissTutorialEarly;

- (NetworkSetupCell *)configureNetworkSetupCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)evaluateShowConditions:(NSDictionary *)conditions forCell:(NetworkSetupCell *)cell;

- (void)evaluateChangesForCell:(NetworkSetupCell *)cell;
@end
