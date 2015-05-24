//
//  PCViewController.h
//  Postcard Beta
//
//  Created by Kyle Newsome on 2013-08-23.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworksManager.h"
#import "PCImagePickerController.h"
#import <DBChooser/DBChooser.h>
#import "RMSwipeTableViewCell.h"

#import "PCTaggingSystemView.h"
#import "PCMessageTextView.h"
#import "PCToolbarView.h"

#import "ConnectedNetworksTableDelegate.h"
#import "CameraOptionsTableDelegate.h"
#import "LinkOptionsTableDelegate.h"
#import "SettingsTableDelegate.h"

#import "BWTutorialLib.h"

typedef enum {
    kTableViewStatusNetworks = 0,
    kTableViewStatusCamera,
    kTableViewStatusLink,
    kTableViewStatusSettings
} PCMainTableViewStatus;

typedef enum{
    PCMainViewTutorialStageNetworkButton = 0,
    PCMainViewTutorialStageAddNetwork,
    PCMainViewTutorialStageTapEnable,
    PCMainViewTutorialStageSwipeSettings,
    PCMainViewTutorialStageSwipeHost,
    PCMainViewTutorialStageSwipeDisableHost,
    PCMainViewTutorialStageMediaButton,
    PCMainViewTutorialStageLinkButton,
    PCMainViewTutorialStageSettingsButton,
    PCMainViewTutorialStageSendButton,

} PCMainViewTutorialStages;

#define MAIN_VIEW_TUTORIAL_SHOW_DELAY 0.34f

@interface PCViewController : UIViewController <UIGestureRecognizerDelegate,
        UIImagePickerControllerDelegate,
        UITextViewDelegate,
        UITextFieldDelegate,
        NetworksManagerDelegate,
        UINavigationControllerDelegate,
        RMSwipeTableViewCellDelegate,
        UICollisionBehaviorDelegate,
        UINavigationControllerDelegate,
        PCMessageTextViewDelegate, PCTaggingSystemViewDelegate, PCSuggestionSystemViewDelegate>

/* Activity Progress View */
@property(nonatomic, weak) IBOutlet UILabel *progressLabel;
@property(nonatomic, weak) IBOutlet UIProgressView *activityProgressView;

/* Post View */
@property(nonatomic, weak) IBOutlet UIView *postcardView;
@property(nonatomic, weak) IBOutlet UIView *backSideView;
@property(nonatomic, weak) IBOutlet UIImageView *backSideWatermark;
@property(nonatomic, weak) IBOutlet PCMessageTextView *postTextView;
@property(nonatomic, weak) IBOutlet PCTaggingSystemView *taggingSystemView;

/* Tutorial View */
@property(nonatomic, weak) IBOutlet BWTutorialView *tutorialView;
@property(nonatomic) PCMainViewTutorialStages tutorialStage;

/* main table */
//TableView Delegation/DataSource objects
@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic) PCMainTableViewStatus tableStatus;
@property(nonatomic, strong) ConnectedNetworksTableDelegate *networksTableDelegate;
@property(nonatomic, strong) CameraOptionsTableDelegate *cameraOptionsTableDelegate;
@property(nonatomic, strong) LinkOptionsTableDelegate *linkOptionsTableDelegate;
@property(nonatomic, strong) SettingsTableDelegate *settingsTableDelegate;

/* Layout */
@property(nonatomic, weak) IBOutlet UIView *typingArea;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *messageTaggingSystemConstraint;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *typingAreaHeightConstraint;

/* Postcard/Image/Video */
@property(nonatomic, strong) PCSocialActivity *currentPostcard;

/* Options bar */
/* These are currently duplicated in the optionsBarView */
@property(nonatomic, weak) IBOutlet PCToolbarView *optionsBarView;
@property(nonatomic, weak) IBOutlet UIView *networkCountView;
@property(nonatomic, weak) IBOutlet UIImageView *networkCountBGImageView;
@property(nonatomic, weak) IBOutlet UILabel *networkCountLabel;

//toolbar buttons
@property(nonatomic, weak) IBOutlet UIButton *networksButton;
@property(nonatomic, weak) IBOutlet UIButton *cameraButton;
@property(nonatomic, weak) IBOutlet UIButton *attachmentButton;
@property(nonatomic, weak) IBOutlet UIButton *settingsButton;
//toolbar indicators
@property(nonatomic, weak) IBOutlet UIImageView *cameraAttachmentIndicator;
@property(nonatomic, weak) IBOutlet UIImageView *linkAttachmentIndicator;
@property(nonatomic, weak) IBOutlet UILabel *postCharacterCount;


- (void)showTutorial:(NSNumber *)stage;
- (void)showTutorialStage:(PCMainViewTutorialStages)stage;
- (IBAction)dismissTutorial;
- (IBAction)dismissTutorialEarly;

/* End Options Bar */

- (IBAction)setupNetworks;

- (IBAction)attachMedia;

- (IBAction)attachFile;

- (IBAction)showSettings;

- (IBAction)sendPost;

- (void)postActivity;

- (void)updateNetworkCount;

- (void)calculateCharacterCount;

- (void)setupNetworkProgressViews:(PCSocialActivity *)activity;

- (void)removeNetworkProgressViews;

- (void)resignKeyboard;

@end
