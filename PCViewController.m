//
//  PCViewController.m
//  Postcard Beta
//
//  Created by Kyle Newsome on 2013-08-23.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "PCViewController.h"

#import "NetworkProgressView.h"
#import "PCDataDelegate.h"

#import "Network.h"
#import "NetworkSettingsViewController.h"

#import "PushPopAnimationController.h"
#import "EdgeSwipeInteractionController.h"

#import "PCStateManager.h"
#import "PCURLHandler.h"
#import "NetworkSetupViewController.h"
#import "PurchaseViewController.h"

#import "PCTutorialManager.h"
#import "UIImage+animatedGIF.h"
#import "UIView+SDCAutoLayout.h"

#import "RFRateMe.h"

@interface PCViewController ()

@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic, weak) NetworksManager *networksManager;

@property(nonatomic) NSUInteger currentCharLimit;

//Animation
@property(nonatomic, strong) NSMutableArray *networkProgressViews;

@property(nonatomic, strong) UIDynamicAnimator *animator;
@property(nonatomic, strong) UIGravityBehavior *gravity;
@property(nonatomic, strong) UICollisionBehavior *collision;
@property(nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@property(nonatomic, strong) PushPopAnimationController *pushPopAnimationController;
@property(nonatomic, strong) EdgeSwipeInteractionController *interactionController;

@end

@implementation PCViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    [PCStateManager sharedInstance].postcardVC = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.hidesBackButton = YES;

    self.dataDelegate = [PCDataDelegate sharedInstance];

    self.networksManager = [NetworksManager sharedInstance];
    _networksManager.rootViewController = self;
    _networksManager.delegate = self;

    //Setup self as nav controller delegate and prep animation/interaction controllers
    self.navigationController.delegate = self;
    self.pushPopAnimationController = PushPopAnimationController.new;
    self.interactionController = EdgeSwipeInteractionController.new;

    //Setup TableView delegates
    self.networksTableDelegate = [[ConnectedNetworksTableDelegate alloc] initWithTable:_tableView andViewController:self];
    self.cameraOptionsTableDelegate = [[CameraOptionsTableDelegate alloc] initWithTable:_tableView andViewController:self];
    self.linkOptionsTableDelegate = [[LinkOptionsTableDelegate alloc] initWithTable:_tableView andViewController:self];
    self.settingsTableDelegate = [[SettingsTableDelegate alloc] initWithTable:_tableView andViewController:self];

    [_networksTableDelegate makeActiveDelegateAndRevealFromRight:NO];
    _tableStatus = kTableViewStatusNetworks;
    _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(44.0f, 0, 0, 0);

    _postTextView.postcardVC = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tutorialDidReset) name:@"TutorialDidReset" object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification  object:nil];
    
    [self updateNetworkCount];
    [self newPost];
}

- (void)dealloc {
    [PCStateManager sharedInstance].postcardVC = nil;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)keyboardDidShow:(NSNotification *)notification{
    NSLog(@"Keyboard Did Show, %@", notification.userInfo);
    NSValue *keyboardRectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrame = keyboardRectValue.CGRectValue;
    CGFloat typingAreaHeight = _postcardView.frame.size.height - 44.0f - 64.0f - keyboardFrame.size.height;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2f
                         animations:^{
                             _typingAreaHeightConstraint.constant = typingAreaHeight;
                             [self.view layoutIfNeeded];
                         }];
    });
    
}

- (void)viewWillAppear:(BOOL)animated {
    _tableView.contentInset = UIEdgeInsetsMake(44.0f, 0.0f, 0.0f, 0.0f);
}

- (void)viewDidAppear:(BOOL)animated {
    BWLog(@"");
    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
        if (_dataDelegate.fetchedConnectedNetworksController.fetchedObjects.count == 0 || self.tutorialStage == 0) {
            [self showTutorialStage:PCMainViewTutorialStageNetworkButton];
        } else {
            [self showTutorialStage:self.tutorialStage];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showTutorial:(NSNumber *)stage {
    [self showTutorialStage:(PCMainViewTutorialStages) stage.intValue];
}

- (void)showTutorialStage:(PCMainViewTutorialStages)stage {
    self.tutorialStage = stage;
    [_tutorialView showFromIndex:stage];
}

- (void)tutorialDidReset {
    [self showTutorialStage:PCMainViewTutorialStageNetworkButton];
}

- (IBAction)dismissTutorial {
    [_tutorialView dismiss];
    [PCTutorialManager setMainViewTutorialAsWatched];
    [_postTextView becomeFirstResponder];
}

- (IBAction)dismissTutorialEarly {
    [_tutorialView dismiss];
    [PCTutorialManager setMainViewTutorialAsWatched];
    [PCTutorialManager setNetworkSetupTutorialAsWatched];
    [PCTutorialManager setNetworkSettingsTutorialAsWatched];
    [_postTextView becomeFirstResponder];
}

#pragma mark - Interface Builder Actions

- (IBAction)setupNetworks {
    [self resignKeyboard];
    self.networksButton.alpha = 1.0f;

    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
        [self showTutorialStage:PCMainViewTutorialStageAddNetwork];
    }

    if (_tableStatus != kTableViewStatusNetworks) {
        self.cameraButton.alpha = 0.7f;
        self.attachmentButton.alpha = 0.7f;
        self.settingsButton.alpha = 0.7f;
        [_networksTableDelegate makeActiveDelegateAndRevealFromRight:NO];
        _tableStatus = kTableViewStatusNetworks;
    }
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)attachMedia {
    [self resignKeyboard];
    self.cameraButton.alpha = 1.0f;

    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
        [self performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageLinkButton) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
    }

    if (_tableStatus != kTableViewStatusCamera) {
        self.networksButton.alpha = 0.7f;
        self.attachmentButton.alpha = 0.7f;
        self.settingsButton.alpha = 0.7f;
        [_cameraOptionsTableDelegate makeActiveDelegateAndRevealFromRight:(_tableStatus < kTableViewStatusCamera)];
        _tableStatus = kTableViewStatusCamera;
    }
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)attachFile {
    [self resignKeyboard];
    self.attachmentButton.alpha = 1.0f;

    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
        [self performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageSettingsButton) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
    }

    if (_tableStatus != kTableViewStatusLink) {
        self.networksButton.alpha = 0.7f;
        self.cameraButton.alpha = 0.7f;
        self.settingsButton.alpha = 0.7f;
        [_linkOptionsTableDelegate makeActiveDelegateAndRevealFromRight:(_tableStatus < kTableViewStatusLink)];
        _tableStatus = kTableViewStatusLink;
    }
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)showSettings {
    [self resignKeyboard];
    self.settingsButton.alpha = 1.0f;
    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
        [self performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageSendButton) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
    }

    if (_tableStatus != kTableViewStatusSettings) {
        self.networksButton.alpha = 0.7f;
        self.cameraButton.alpha = 0.7f;
        self.attachmentButton.alpha = 0.7f;
        [_settingsTableDelegate makeActiveDelegateAndRevealFromRight:YES];
        _tableStatus = kTableViewStatusSettings;
    }
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (IBAction)sendPost {
    //Scan message for urls

    NSString *message = _postTextView.text;
    //if we have a url, remove it from the message
    if (_currentPostcard.messageLink != nil && _currentPostcard.messageLink.originalUrl != nil) {
        message = [[message stringByReplacingOccurrencesOfString:_currentPostcard.messageLink.originalUrl withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    //Attach message
    _currentPostcard.message = message;

    if (_postTextView.text.length == 0 & _currentPostcard.messageLink == nil && _currentPostcard.messageMedia == nil) {
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"No message attached", nil)
                                                          message:NSLocalizedString(@"Your message is empty and no link or media are attached", nil)
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
        return;
    }

    if (![PCAppDelegate sharedInstance].reachChecker.isReachable) {
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"No internet connection", nil)
                                                          message:NSLocalizedString(@"You currently have no connection to the internet", nil)
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
        return;
    }


    NSUInteger networkCount = 0;
    NSUInteger networkIndex = 0;
    for (ConnectedNetwork *network in _dataDelegate.fetchedConnectedNetworksController.fetchedObjects) {
        if ([network.isEnabled boolValue]) {
            networkCount++;
            Network *networkInstance = (Network *) network.instance;

            BOOL valid = [self validatePostActivityAgainstNetwork:networkInstance];
            if (!valid) {
                return;
            }
        }
        if (networkIndex == 0 && network.isHost.boolValue) {
            BWLog(@"Breaking network validation early, since we have a host");
            //if we have a host, we don't need to check the remaining networks
            break;
        }
        networkIndex++;
    }

    if (networkCount == 0) {
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"No networks selected", nil)
                                                          message:NSLocalizedString(@"You need to send your message to at least one network", nil)
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
        return;
    }

    [self postActivity];
    [self resignKeyboard];
}

- (BOOL)validatePostActivityAgainstNetwork:(Network *)networkInstance {
    NSDictionary *eligibility = [networkInstance confirmPostActivityEligibility:_currentPostcard];

    BWLog(@"%@ eligibility -> %@", networkInstance, eligibility);

    if (![eligibility[@"success"] boolValue]) {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ to %@", nil), eligibility[@"reason"], networkInstance.name.capitalizedString];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"If you want to post this as-is, toggle the 'host' function on another qualifying network. This way you can link to the full content.", nil), networkInstance.name.capitalizedString];

        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];

        NSURL *url = [[NSBundle mainBundle] URLForResource:@"hosting-demo" withExtension:@"gif"];
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.image = [UIImage animatedImageWithAnimatedGIFURL:url];
        [alert.contentView addSubview:imageView];
        [imageView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [imageView sdc_horizontallyCenterInSuperview];
        [imageView sdc_pinHeight:imageView.image.size.height / 2];
        [imageView sdc_pinWidth:imageView.image.size.width / 2];
        [alert.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:NSDictionaryOfVariableBindings(imageView)]];

        [alert show];
        return NO;
    }
    return YES;
}

#pragma mark - Non-UI facing functions

- (void)newPost {
    self.currentPostcard = [[PCSocialActivity alloc] init];
    _postTextView.text = @"";
    [_taggingSystemView reset];
    _postCharacterCount.text = [NSString stringWithFormat:@"%d", _currentCharLimit];
    _postcardView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 2);
    _postcardView.hidden = NO;

    self.linkAttachmentIndicator.hidden = YES;
    self.cameraAttachmentIndicator.hidden = YES;

    [self.tableView reloadData];

    [UIView animateWithDuration:0.56f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:14.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        _postcardView.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
        _cameraButton.alpha = 0.7f;
        _networksButton.alpha = 0.7f;
        _attachmentButton.alpha = 0.7f;
        _settingsButton.alpha = 0.7f;
    }                completion:nil];
    [_postTextView becomeFirstResponder];
}

- (void)postActivity {
    PCSocialActivity *activity = _currentPostcard;

    //Setup Date
    NSDateFormatter *formatter;
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString;
    dateString = [formatter stringFromDate:[NSDate date]];
    activity.date = dateString;

    // Tags Management
    NSMutableArray *allTags = [NSMutableArray array];
    //Setup private tags
    NSArray *tags = _taggingSystemView.arrayOfTags;
    if (tags != nil) {
        activity.tags = [tags componentsJoinedByString:@","];
        [allTags addObjectsFromArray:tags];
    }
    //Look for public tags
    NSArray *hashtags = _postTextView.getHashtags;
    if (hashtags != nil) {
        [allTags addObjectsFromArray:hashtags];
    }
    if (allTags.count > 0) {
        [_dataDelegate handleTagsImport:allTags];
    }

    for (ConnectedNetwork *network in _dataDelegate.fetchedConnectedNetworksController.fetchedObjects) {
        if ([network.isEnabled boolValue]) {
            [activity addNetwork:network];
        }
    }

    _progressLabel.hidden = NO;
    _progressLabel.text = NSLocalizedString(@"Preparing postcard...", nil);
    _activityProgressView.hidden = NO;
    [_activityProgressView setProgress:0.0f animated:NO];
    [self setupNetworkProgressViews:activity];

    [UIView animateWithDuration:0.56f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:5.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        _postcardView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, -[UIScreen mainScreen].bounds.size.height / 2);
        _cameraButton.alpha = 0.7f;
        _networksButton.alpha = 0.7f;
        _attachmentButton.alpha = 0.7f;
        _settingsButton.alpha = 0.7f;
    }                completion:nil];

    [UIView animateWithDuration:1.0f animations:^{
        _backSideWatermark.alpha = 0.0f;
    }];

    [_networksManager performSelector:@selector(postActivity:) withObject:activity afterDelay:1.8f];
}

- (void)setupNetworkProgressViews:(PCSocialActivity *)activity {
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.gravity = [[UIGravityBehavior alloc] initWithItems:nil];
    _gravity.gravityDirection = CGVectorMake(0, -1);
    _gravity.magnitude = 1.66f;
    self.collision = [[UICollisionBehavior alloc] initWithItems:nil];
    [_collision addBoundaryWithIdentifier:@"topInvisibleEdge" fromPoint:CGPointMake(0, 76) toPoint:CGPointMake(320, 76)];
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:nil];
    _itemBehavior.elasticity = 0.2f;

    [_animator addBehavior:_gravity];
    [_animator addBehavior:_collision];
    [_animator addBehavior:_itemBehavior];

    self.networkProgressViews = [NSMutableArray array];
    for (ConnectedNetwork *network in activity.networks) {

        NetworkProgressView *networkProgressView = [[[NSBundle mainBundle] loadNibNamed:@"NetworkProgressView" owner:self options:nil] objectAtIndex:0];

        networkProgressView.connectedNetwork = network;

        [_networkProgressViews addObject:networkProgressView];

        CGFloat yPositionStart = 284 + (60 * [_networkProgressViews count]);

        networkProgressView.center = CGPointMake(160, yPositionStart);
        networkProgressView.alpha = 0;
        [_backSideView addSubview:networkProgressView];

        [_gravity addItem:networkProgressView];
        [_collision addItem:networkProgressView];
        [_itemBehavior addItem:networkProgressView];
        [UIView animateWithDuration:0.20f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             //networkProgressView.center = CGPointMake(160, yPositionEnd);
                             networkProgressView.alpha = 1;
                         }
                         completion:nil];
    }
}

- (void)removeNetworkProgressViews {
    self.collision = nil;
    self.gravity = nil;
    self.animator = nil;
    for (NetworkProgressView *networkProgressView in _networkProgressViews) {
        [networkProgressView removeFromSuperview];
    }
    [_networkProgressViews removeAllObjects];
    self.networkProgressViews = nil;
}

- (void)resignKeyboard {
    [_postTextView resignFirstResponder];
    if ([_taggingSystemView resignFirstResponder]) {
        [self.optionsBarView showMainOptions];
    }
}

- (void)updateNetworkCount {
    NSUInteger count = 0;
    BOOL showTags = NO;
    NSUInteger charLimit = 9999;

    //iterate over networks and evaluate their properties
    NSUInteger index = 0;
    BOOL hasHost = NO;
    for (ConnectedNetwork *network in _dataDelegate.fetchedConnectedNetworksController.fetchedObjects) {
        //determine if we have a host
        if (index == 0 && network.isHost.boolValue) {
            hasHost = YES;
        }
        //we only need to work with enabled networks
        if (network.isEnabled.boolValue) {
            count++;
            Network *networkInstance = (Network *) [network instance];
            //any networks that allows private tagging will enabled this, host or not
            if (networkInstance.usesTags) {
                showTags = YES;
            }
            //we only want to calculate charLimit when we are working with a host network, or if there is no host network
            if ((index == 0 && hasHost) || !hasHost) {
                //establish network's character limit
                if (networkInstance.charLimit > 0 && networkInstance.charLimit < charLimit) {
                    charLimit = (NSUInteger) networkInstance.charLimit;
                }
            }
        }
        index++;
    }

    //set network count indicator
    _networkCountLabel.text = [NSString stringWithFormat:@"%d", count];

    //show/hide character count limit
    self.currentCharLimit = charLimit;
    self.postCharacterCount.hidden = !(charLimit < 9999);
    [self calculateCharacterCount];

    //show/hide tagging system
    if (showTags) {
        [_typingArea addConstraint:_messageTaggingSystemConstraint];
        _taggingSystemView.hidden = NO;
        [UIView animateWithDuration:0.24f
                         animations:^{
                             [_typingArea layoutIfNeeded];
                             _taggingSystemView.alpha = 1.0f;
                         }];
    } else {
        [_typingArea removeConstraint:_messageTaggingSystemConstraint];
        [UIView animateWithDuration:0.24f
                         animations:^{
                             [_typingArea layoutIfNeeded];
                             _taggingSystemView.alpha = 0.0f;
                         }
                         completion:^(BOOL complete) {
                             _taggingSystemView.hidden = YES;
                         }
        ];
    }
}

#pragma mark - UICollisionBehaviorDelegate
- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id <UIDynamicItem>)item withBoundaryIdentifier:(id <NSCopying>)identifier atPoint:(CGPoint)p {
    if ([(NSString *) identifier isEqualToString:@"topOfView"]) {
        [_postTextView becomeFirstResponder];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidEndEditing:(UITextView *)textView {
    [self calculateCharacterCount];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView == _postTextView) {
        [self calculateCharacterCount];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.networksButton.alpha = 0.7f;
    self.cameraButton.alpha = 0.7f;
    self.attachmentButton.alpha = 0.7f;
    self.settingsButton.alpha = 0.7f;
    [self.optionsBarView showMainOptions];
}

#pragma mark - UITextView handling

- (void)calculateCharacterCount {
    NSInteger length = _currentCharLimit;
    length -= [_postTextView.text length];
    length -= (_currentPostcard.messageMedia != nil) ? 23 : 0;
    if (_currentPostcard.messageLink != nil) { //a url was detected in the text
        length -= 23;
        //Check if original url occurs within the message text and add its char count back, if so
        NSString *originalUrl = _currentPostcard.messageLink.originalUrl;
        if (originalUrl != nil && [_postTextView.text rangeOfString:originalUrl].location != NSNotFound) {
            length += _currentPostcard.messageLink.originalUrl.length;
        }
    }

    _postCharacterCount.text = [NSString stringWithFormat:@"%d", length];
    if (length < 0) {
        _postCharacterCount.textColor = [PCColorPalette lightOrangeColor];
        CGFloat t = 4.0;
        CGAffineTransform translateRight = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0);
        CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0);
        _postCharacterCount.transform = translateLeft;
        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
            [UIView setAnimationRepeatCount:2.0];
            _postCharacterCount.transform = translateRight;
        }                completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.03 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _postCharacterCount.transform = CGAffineTransformIdentity;
                }                completion:NULL];
            }
        }];
    } else {
        _postCharacterCount.textColor = [UIColor whiteColor];
    }
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *destinationVC = segue.destinationViewController;

    [_tutorialView dismiss];

    //Add Back Button
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
    backButton.image = [UIImage imageNamed:@"back-chevron-left"];
    backButton.action = @selector(back);
    backButton.target = destinationVC;
    destinationVC.navigationItem.leftBarButtonItem = backButton;

    if ([segue.identifier isEqualToString:@"pushSettings"]) {

        if (![PCTutorialManager hasWatchedMainViewTutorial] && self.tutorialStage == PCMainViewTutorialStageSwipeSettings) {
            self.tutorialStage = PCMainViewTutorialStageSwipeHost;
        }

        NetworkSettingsViewController *settingsVC = (NetworkSettingsViewController *) destinationVC;
        NSIndexPath *indexPath = (NSIndexPath *) sender;
        ConnectedNetwork *network = [_dataDelegate.fetchedConnectedNetworksController.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
        [settingsVC setNetworkForSettings:network];
    } else if ([segue.identifier isEqualToString:@"pushNetworkSetup"]) {
        if (![PCTutorialManager hasWatchedMainViewTutorial] && self.tutorialStage == PCMainViewTutorialStageAddNetwork) {
            self.tutorialStage = PCMainViewTutorialStageTapEnable;
        }
        NetworkSetupViewController *setupVC = (NetworkSetupViewController *) destinationVC;
        if ([sender isKindOfClass:[PCURLHandler class]]) {
            setupVC.loadParameters = [PCURLHandler sharedInstance].parameters;
        }
    } else if ([segue.identifier isEqualToString:@"pushPurchase"]) {
        if (![PCTutorialManager hasWatchedMainViewTutorial] && self.tutorialStage == PCMainViewTutorialStageAddNetwork) {
            self.tutorialStage = PCMainViewTutorialStageTapEnable;
        }
    }
}

#pragma mark - NetworksManagerDelegate

- (void)socialActivity:(PCSocialActivity *)activity didBeginPostingToNetwork:(NSUInteger)index {
    BWLog(@"%d", index);
    ConnectedNetwork *network = [activity.networks objectAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressLabel.text = [NSString stringWithFormat:@"Posting to %@...", [[(Network *) network.instance name] capitalizedString]];
    });
}

- (void)socialActivity:(PCSocialActivity *)activity didCompletePostingToNetwork:(NSUInteger)index {
    NetworkProgressView *networkProgressView = [_networkProgressViews objectAtIndex:index];
    ConnectedNetwork *network = [activity.networks objectAtIndex:index];
    float progress = (float) _networksManager.currentNetworkCompletionCount / (float) activity.networks.count;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.8f animations:^{
            networkProgressView.alpha = 0.0f;
        }];
        [networkProgressView updateProgress:1.0f];
        [_activityProgressView setProgress:progress animated:YES];

        [_collision removeItem:networkProgressView];
        _progressLabel.text = [NSString stringWithFormat:@"Finished posting to %@", [[(Network *) network.instance name] capitalizedString]];
    });
}

- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index updatedWithProgress:(double)fraction {
    BWLog(@" %f ", fraction);
    NetworkProgressView *networkProgressView = [_networkProgressViews objectAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        [networkProgressView updateProgress:fraction];
    });
}

- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index updatedWithMessage:(NSString *)message {
    NetworkProgressView *networkProgressView = [_networkProgressViews objectAtIndex:index];
    [networkProgressView updateProgressWithMessage:message];
}

- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index didFailwithError:(NSError *)error {
    NetworkProgressView *networkProgressView = [_networkProgressViews objectAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        [networkProgressView updateProgressWithError:1.0f andMessage:error.localizedDescription];
        _progressLabel.text = [NSString stringWithFormat:@"Error posting!"];
    });
}

- (void)socialActivityComplete:(PCSocialActivity *)activity {
    NSMutableDictionary *networkDictionary = [NSMutableDictionary dictionary];
    for (ConnectedNetwork *network in activity.networks) {
        if (networkDictionary[network.networkId] == nil) {
            networkDictionary[network.networkId] = @1;
        } else {
            NSNumber *count = networkDictionary[network.networkId];
            networkDictionary[network.networkId] = @(count.integerValue + 1);
        }
    }
    BWLog(@"Activity Compelted: %@", networkDictionary);
    [Flurry logEvent:@"Activity Completed" withParameters:networkDictionary];

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.0f animations:^{
            _backSideWatermark.alpha = 1.0f;
        }                completion:^(BOOL complete) {
            //Check if this is a good time to request a review
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            int timesOpened = [defaults integerForKey:@"timesOpened"];
            BWLog(@"App has been opened %d times", timesOpened);
            if (timesOpened >= 4) {
                [RFRateMe showRateAlert];
            }
            [defaults setInteger:(timesOpened + 1) forKey:@"timesOpened"];
            [defaults synchronize];
        }];
        [self performSelector:@selector(removeNetworkProgressViews) withObject:nil afterDelay:3.0f];
        [self performSelector:@selector(newPost) withObject:nil afterDelay:2.0f];
    });
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC {

    if (operation == UINavigationControllerOperationPush) {
        _interactionController.isRightToLeftMode = _pushPopAnimationController.isRightToLeftMode = NO;
        [_interactionController wireToViewController:toVC];
    }

    _pushPopAnimationController.reverse = operation == UINavigationControllerOperationPop;
    return _pushPopAnimationController;
}

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController {
    return _interactionController.interactionInProgress ? _interactionController : nil;
}

#pragma mark - TaggingSystemViewDelegate
- (void)taggingSystemDidBeginEditingTagField:(PCTaggingSystemView *)taggingSystem {
    self.cameraButton.alpha = 0.7f;
    self.networksButton.alpha = 0.7f;
    self.attachmentButton.alpha = 0.7f;
    self.settingsButton.alpha = 0.7f;
    [self.optionsBarView hideMainOptions];
}

- (void)taggingSystem:(PCTaggingSystemView *)taggingSystem textForCurrentTag:(NSString *)text {
    PCSuggestionSystemViewFilterMode filterMode = (_postTextView.state == PCMessageTextViewStateMention) ? PCSuggestionSystemViewFilterModeMentions : PCSuggestionSystemViewFilterModeTags;
    [_optionsBarView.suggestionSystemView setText:text withFilteringMode:filterMode];
}

#pragma mark - SuggestionSystemViewDelegate
- (void)suggestionSystemView:(PCSuggestionSystemView *)suggestionSystemView didSelectText:(NSString *)text {
    if (_postTextView.state == PCMessageTextViewStateNormal) {
        [_taggingSystemView setTextForCurrentTag:text];
        return;
    } else if (_postTextView.state == PCMessageTextViewStateHashtag) {
        [_postTextView setTextForCurrentTag:text];
    } else if (_postTextView.state == PCMessageTextViewStateMention) {
        [_postTextView setTextForCurrentMention:text];
    }
}

#pragma mark - MessageTextViewDelegate
- (void)messageTextView:(PCMessageTextView *)messageTextView enteringState:(PCMessageTextViewState)state {
    if (state != PCMessageTextViewStateNormal) {
        [self.optionsBarView hideMainOptions];
    } else {
        [self.optionsBarView showMainOptions];
    }
}

- (void)messageTextView:(PCMessageTextView *)messageTextView currentSpecialWordText:(NSString *)text {
    if (_postTextView.state == PCMessageTextViewStateHashtag) {
        [_optionsBarView.suggestionSystemView setText:text withFilteringMode:PCSuggestionSystemViewFilterModeTags];
    } else if (_postTextView.state == PCMessageTextViewStateMention) {
        [_optionsBarView.suggestionSystemView setText:text withFilteringMode:PCSuggestionSystemViewFilterModeMentions];
    }
}

@end