//
//  NetworkSetupViewController.h
//  paradigm
//
//  Created by Kyle Newsome on 2012-12-25.
//  Copyright (c) 2012 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PCViewController;

typedef enum{
    PCNetworkSetupTutorialStageScrollNetworks = 0,
    PCNetworkSetupTutorialStageExplainCustom,

} PCNetworkSetupTutorialStages;

@interface NetworkSetupViewController : UIViewController
<UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

/* Tutorial View */
@property(nonatomic, weak) IBOutlet BWTutorialView *tutorialView;

@property(nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;

@property(nonatomic, weak) IBOutlet UILabel *networkNameLabel;
@property(nonatomic, weak) IBOutlet UICollectionView *networksCollectionView;
@property(nonatomic, weak) IBOutlet UITableView *networkDetailsTableView;

@property(nonatomic, weak) IBOutlet UIButton *btnLinkNetwork;

@property(nonatomic, weak) PCViewController *pcViewController;

@property(nonatomic, strong) NSDictionary *loadParameters;

- (IBAction)back;

- (void)setupWithLoadParameters:(NSDictionary *)parameters;

-(IBAction)nextTutorialStage;
-(IBAction)dismissTutorial;

- (IBAction)dismissTutorialEarly;
@end
