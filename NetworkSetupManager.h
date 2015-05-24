//
//  NetworkSetupManager.h
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-02.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network.h"
#import "NetworkSetupCell.h"

typedef enum {
    kNetworkCredentialsEntryMode = 0,
    kNetworkAccountSelectionMode
} NetworkSetupDetailsTableMode;

@class NetworkSetupViewController;

@interface NetworkSetupManager : NSObject <UITableViewDelegate, UITableViewDataSource, NetworkSetupCellDelegate>

@property (nonatomic, strong) NSDictionary *networkInfo;
@property (nonatomic, weak) NetworkSetupViewController *networkSetupVC;

- (id)initWithSetupViewController:(NetworkSetupViewController *)setupVC;

- (void)setupNetworkInfo:(NSDictionary *)info;

-(void)network:(Network *)network showAccountSelectionOptions:(NSArray *)options;
-(void)network:(Network *)network setupCompleted:(BOOL)success properties:(NSDictionary *)properties;

@end
