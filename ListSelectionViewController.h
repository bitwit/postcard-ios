//
//  ListSelectionViewController.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-22.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NetworkSetupListSelectionCell;

@interface ListSelectionViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

-(void)setWithNetworkSetupCell:(NetworkSetupListSelectionCell *)cell andOptions:(NSArray *)options;

@end
