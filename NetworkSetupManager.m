//
//  NetworkSetupManager.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-02.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "NetworkSetupViewController.h"
#import "NetworkSetupFieldCell.h"
#import "NetworksManager.h"
#import "Network.h"
#import "NetworkSetupAccessButtonCell.h"
#import "NetworkSetupMessageCell.h"
#import "NetworkSetupURLButtonCell.h"
#import "PCTutorialManager.h"
#import "PCDataDelegate.h"

@interface NetworkSetupManager ()

@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic) BOOL hasInitializedTable;
@property(nonatomic, strong) NSArray *setupFields;
@property(nonatomic, strong) Network *socialNetwork;
@property(nonatomic, strong) NSArray *accountSelectionOptions;
@property(nonatomic, strong) NSMutableArray *cells;
@property(nonatomic) NetworkSetupDetailsTableMode tableMode;

@property(nonatomic, strong) UIToolbar *accessoryView;
@property(nonatomic, strong) UIBarButtonItem *prev;
@property(nonatomic, strong) UIBarButtonItem *next;

@property(nonatomic) NSInteger currentEditingIndex;

- (void)getAccess;

@end

@implementation NetworkSetupManager

- (id)initWithSetupViewController:(NetworkSetupViewController *)setupVC {
    self = [self init];
    if (self) {
        self.networkSetupVC = setupVC;
        self.dataDelegate = [PCDataDelegate sharedInstance];
        self.hasInitializedTable = NO;
    }
    return self;
}

- (void)setupNetworkInfo:(NSDictionary *)info {
    self.networkInfo = info;
    self.setupFields = [_networkInfo valueForKey:@"setupFields"];

    if (_tableMode == kNetworkAccountSelectionMode) {
        //we just need to do a fresh whole reset in this case
        self.cells = [NSMutableArray array];
        self.tableMode = kNetworkCredentialsEntryMode;
        [self.networkSetupVC.networkDetailsTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                                   withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        self.tableMode = kNetworkCredentialsEntryMode;
        [self setupNetworkCells];
    }
}

- (void)setupNetworkCells {
    self.cells = [NSMutableArray array];
    UITableView *tableView = self.networkSetupVC.networkDetailsTableView;
    NSInteger rowCount = -1;
    [tableView beginUpdates];

    if (!_hasInitializedTable) {
        self.hasInitializedTable = YES;
        [tableView insertRowsAtIndexPaths:@[
                [NSIndexPath indexPathForRow:0 inSection:0],
                [NSIndexPath indexPathForRow:1 inSection:0],
        ]                withRowAnimation:UITableViewRowAnimationFade];
        rowCount = 2;
    }

    if (rowCount == -1) {   //we haven't calculated a count yet, so the table must be initialized
        rowCount = [tableView numberOfRowsInSection:0];
    }

    if (rowCount > 2) {
        NSUInteger oldFieldCount = (NSUInteger) (rowCount - 2);
        NSMutableArray *removePaths = [[NSMutableArray alloc] initWithCapacity:oldFieldCount];
        for (int i = 1; i <= oldFieldCount; i++) {
            [removePaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        [tableView deleteRowsAtIndexPaths:removePaths withRowAnimation:UITableViewRowAnimationFade];
    }

    NSMutableArray *insertPaths = [[NSMutableArray alloc] initWithCapacity:_setupFields.count];
    for (int i = 1; i <= _setupFields.count; i++) {
        [insertPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    [tableView insertRowsAtIndexPaths:insertPaths withRowAnimation:UITableViewRowAnimationFade];
    [tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [tableView endUpdates];
}

- (void)getAccess {
    //Delete any lingering cookies before next auth process
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    self.socialNetwork = [[NSClassFromString([_networkInfo valueForKey:@"className"]) alloc] init];
    NSUInteger i = 0;
    for (NSDictionary *field in _setupFields) {
        if ([field[@"type"] isEqualToString:@"Field"]) {
            NetworkSetupFieldCell *cell = (NetworkSetupFieldCell *) _cells[i + 1];
            NSString *value = cell.getValue;
            if([value isEqualToString:@""]){
                SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"Complete all fields", nil)
                                                                  message:NSLocalizedString(@"You can't set this network up without completing all the fields", nil)
                                                                 delegate:nil
                                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                        otherButtonTitles:nil];
                [alert show];
                return;
            }
            [_socialNetwork setValue:value forKey:[field valueForKey:@"property"]];
        }
        i++;
    }

    NSIndexPath *idxPath = [NSIndexPath indexPathForRow:(_setupFields.count + 1) inSection:0];
    NetworkSetupAccessButtonCell *cell = (NetworkSetupAccessButtonCell *) [self.networkSetupVC.networkDetailsTableView cellForRowAtIndexPath:idxPath];
    cell.activityIndicator.hidden = NO;
    [cell.activityIndicator startAnimating];

    [_socialNetwork getAccessWithSetupManager:self];
}

#pragma mark - NetworkDelegate
- (void)network:(Network *)network setupCompleted:(BOOL)success properties:(NSDictionary *)properties {
    if (success) {
        [_dataDelegate newConnectedNetwork:_socialNetwork withTitle:properties[@"title"]];
        self.socialNetwork = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.networkSetupVC.navigationController popViewControllerAnimated:YES];
        });
    } else {
        BWLog(@"Failed to set up...");
        self.socialNetwork = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *errorMessage = (properties[@"message"] != nil) ? properties[@"message"] : @"Unspecified error";
            SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:@"Error Adding Network"
                                                              message:errorMessage
                                                             delegate:nil
                                                    cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                    otherButtonTitles:nil];
            [alert show];
            NSIndexPath *idxPath = [NSIndexPath indexPathForRow:(_setupFields.count + 1) inSection:0];
            NetworkSetupAccessButtonCell *cell = (NetworkSetupAccessButtonCell *) [self.networkSetupVC.networkDetailsTableView cellForRowAtIndexPath:idxPath];
            [cell.activityIndicator stopAnimating];
            cell.activityIndicator.hidden = YES;
        });
    }
}

- (void)network:(Network *)network showAccountSelectionOptions:(NSArray *)options {
    BWLog(@"");
    self.tableMode = kNetworkAccountSelectionMode;
    self.accountSelectionOptions = options;
    self.cells = nil;  //clear out the old cells

    dispatch_async(dispatch_get_main_queue(), ^{
        //self.networkSetupVC.networkDetailsTableView.scrollEnabled = YES;
        [self.networkSetupVC.networkDetailsTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.networkSetupVC.networkDetailsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    });
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (!_hasInitializedTable)
        return 0;

    NSUInteger cellCount = 1; //description and setup button

    if (_tableMode == kNetworkCredentialsEntryMode) {
        cellCount += 1; //Description cell added for network
        if (_setupFields != nil) {
            cellCount += _setupFields.count;
        }
    } else if (_tableMode == kNetworkAccountSelectionMode) {
        cellCount += _accountSelectionOptions.count;
    }

    return cellCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tableMode == kNetworkCredentialsEntryMode) {
        if (indexPath.row == 0) {
            NetworkSetupMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NetworkMessageCell"];
            [cell setupWithParameters:nil andValue:[_networkInfo[@"description"] uppercaseString]];
            CGFloat height = cell.height;
            return height;
        } else if (indexPath.row == [self tableView:tableView numberOfRowsInSection:0] - 1) {
            return 100.0f; //link button
        }
        //then it must be a field
        return ([_setupFields[(NSUInteger) indexPath.row - 1][@"type"] isEqualToString:@"URLButton"]) ? 24.0f : 60.0f;
    } else { // (_tableMode == kNetworkAccountSelectionMode)
        return 44.0f;  //account selection cell
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell;
    @try {
        cell = [_cells objectAtIndex:indexPath.row];
        if (cell != nil) {
            return cell;
        }
    }
    @catch (NSException *e) {
        //  BWLog(@"Exception: %@", e);
    }

    static NSString *fieldCellIdentifier = @"NetworkSetupFieldCell";
    static NSString *urlButtonCellIdentifier = @"NetworkSetupURLButtonCell";
    static NSString *linkButtonIdentifier = @"NetworkSetupAccessButtonCell";
    static NSString *accountSelectionIdentifier = @"NetworkAccountSelectionCell";
    static NSString *messageCellIdentifier = @"NetworkMessageCell";

    if (_tableMode == kNetworkCredentialsEntryMode) {

        //top row is always a description
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:messageCellIdentifier];
            NetworkSetupMessageCell *messageCell = (NetworkSetupMessageCell *) cell;
            [messageCell setupWithParameters:nil andValue:[_networkInfo[@"description"] uppercaseString]];
        }
                //next we ay or may not have custom fields per network
        else if (_setupFields != nil) {
            // as long as we aren't on the last cell of this table, it is definitely a setup field
            if (indexPath.row <= _setupFields.count) {
                NSDictionary *fieldInfo = [_setupFields objectAtIndex:(NSUInteger) indexPath.row - 1];
                //different types of setup fields display differently
                if ([fieldInfo[@"type"] isEqualToString:@"Field"]) {
                    NetworkSetupFieldCell *networkCell = [tableView dequeueReusableCellWithIdentifier:fieldCellIdentifier];
                    networkCell.fieldLabel.text = [fieldInfo[@"title"] uppercaseString];
                    networkCell.delegate = self;
                    NSString *propertyName = [[_setupFields objectAtIndex:(NSUInteger) indexPath.row - 1] valueForKey:@"property"];
                    if ([_networkSetupVC.loadParameters[@"network"] isEqualToString:_networkInfo[@"slug"]]) {
                        if (_networkSetupVC.loadParameters[propertyName] != nil) {
                            networkCell.textField.text = _networkSetupVC.loadParameters[propertyName];
                        }
                    }
                    if ([propertyName isEqualToString:@"password"]) {
                        networkCell.textField.secureTextEntry = YES;
                    }
                    cell = networkCell;
                } else if ([fieldInfo[@"type"] isEqualToString:@"URLButton"]) {
                    NetworkSetupURLButtonCell *networkCell = [tableView dequeueReusableCellWithIdentifier:urlButtonCellIdentifier];
                    networkCell.visitButton.titleLabel.text = [fieldInfo[@"title"] uppercaseString];
                    networkCell.urlString = fieldInfo[@"url"];
                    networkCell.delegate = self;
                    cell = networkCell;
                }
            }
                    //otherwise we are ready to display the final button
            else {
                NetworkSetupAccessButtonCell *networkCell = [tableView dequeueReusableCellWithIdentifier:linkButtonIdentifier];
                networkCell.delegate = self;
                networkCell.activityIndicator.hidden = YES;
                networkCell.button.titleLabel.text = [NSLocalizedString(@"Set Up Network", nil) uppercaseString];
                cell = networkCell;
            }
        }
                //otherwise this is a simple setup view, description and setup button only
        else {
            NetworkSetupAccessButtonCell *networkCell = [tableView dequeueReusableCellWithIdentifier:linkButtonIdentifier];
            networkCell.delegate = self;
            networkCell.activityIndicator.hidden = YES;
            networkCell.button.titleLabel.text = [NSLocalizedString(@"Set Up Network", nil) uppercaseString];
            cell = networkCell;
        }
        //
    } else { //(_tableMode == kNetworkAccountSelectionMode)
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:messageCellIdentifier];
            NetworkSetupMessageCell *messageCell = (NetworkSetupMessageCell *) cell;
            [messageCell setupWithParameters:nil andValue:[NSLocalizedString(@"Select an account", nil) uppercaseString]];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:accountSelectionIdentifier];
            cell.textLabel.text = [_accountSelectionOptions objectAtIndex:(NSUInteger) indexPath.row - 1];
        }
    }

    [self.cells insertObject:cell atIndex:indexPath.row];
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tableMode == kNetworkAccountSelectionMode && indexPath.row == 0) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tableMode == kNetworkAccountSelectionMode) {
        if (indexPath.row > 0) {
            [_socialNetwork accountSelected:(NSUInteger) indexPath.row - 1];
        }
    }
}

#pragma mark - Keyboard Accessory View

- (UIToolbar *)keyboardAccessoryView {
    if (self.accessoryView != nil) {
        return self.accessoryView;
    }

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    toolbar.barTintColor = [PCColorPalette mediumBlueColor];
    toolbar.translucent = NO;

    UIBarButtonItem *prev = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-chevron-left"] style:UIBarButtonItemStylePlain target:self action:@selector(previousField)];
    prev.tintColor = [UIColor whiteColor];

    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-chevron-right"] style:UIBarButtonItemStylePlain target:self action:@selector(nextField)];
    next.tintColor = [UIColor whiteColor];

    NSArray *items = @[prev, next];
    [toolbar setItems:items animated:YES];

    self.accessoryView = toolbar;
    self.prev = prev;
    self.next = next;

    return self.accessoryView;
}

- (IBAction)previousField {
    if (_currentEditingIndex <= 1) {
        return;
    }
    NSUInteger prevIndex = (NSUInteger) _currentEditingIndex - 1;
    NetworkSetupCell *cell = (NetworkSetupCell *) _cells[prevIndex];
    if ([cell isKindOfClass:NetworkSetupFieldCell.class]) {
        UITableView *tableView = [_networkSetupVC networkDetailsTableView];
        CGPoint origin = cell.frame.origin;
        CGPoint point = [cell.superview convertPoint:origin toView:tableView];
        CGPoint offset = CGPointZero;
        offset.y += point.y;
        [tableView setContentOffset:offset animated:YES];
        [[(NetworkSetupFieldCell *) cell textField] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3f];
    }
}

- (IBAction)nextField {
    if (_currentEditingIndex >= (_setupFields.count)) {
        return;
    }
    NSUInteger nextIndex = (NSUInteger) _currentEditingIndex + 1;
    NetworkSetupCell *cell = (NetworkSetupCell *) _cells[nextIndex];
    if ([cell isKindOfClass:NetworkSetupFieldCell.class]) {
        UITableView *tableView = [_networkSetupVC networkDetailsTableView];
        CGPoint origin = cell.frame.origin;
        CGPoint point = [cell.superview convertPoint:origin toView:tableView];
        CGPoint offset = CGPointZero;
        offset.y += point.y;
        [tableView setContentOffset:offset animated:YES];
        [[(NetworkSetupFieldCell *) cell textField] performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3f];
    }
}

#pragma mark - NetworkSetupCellDelegate

- (void)networkSetupCellDidBeginEditing:(NetworkSetupCell *)cell {
    self.currentEditingIndex = [[_networkSetupVC networkDetailsTableView] indexPathForCell:cell].row;
    if ([cell isKindOfClass:NetworkSetupFieldCell.class]) {
        UIToolbar *toolbar = [self keyboardAccessoryView];
        self.next.enabled = YES;
        self.prev.enabled = YES;

        if (_currentEditingIndex == 1) {
            self.prev.enabled = NO;
        }

        if (_currentEditingIndex == (_setupFields.count)) {
            self.next.enabled = NO;
        }

        [[(NetworkSetupFieldCell *) cell textField] setInputAccessoryView:toolbar];

        UITableView *tableView = [_networkSetupVC networkDetailsTableView];
        CGPoint origin = cell.frame.origin;
        CGPoint point = [cell.superview convertPoint:origin toView:tableView];
        CGPoint offset = CGPointZero;
        offset.y += point.y;
        [tableView setContentOffset:offset animated:YES];
    }
}

- (void)networkSetupCellWillDismissKeyboard:(NetworkSetupCell *)cell {
    UITableView *tableView = [_networkSetupVC networkDetailsTableView];
    [tableView setContentOffset:CGPointZero animated:YES];
}

- (void)networkSetupCell:(NetworkSetupCell *)cell wantsToVisitURL:(NSString *)urlString {
    [_networkSetupVC performSegueWithIdentifier:@"modalWebView" sender:urlString];
}

-(void)networkSetupCellInitiatedSetup:(NetworkSetupCell *)cell{
    if (![PCAppDelegate sharedInstance].reachChecker.isReachable) {
        SDCAlertView *alert = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"No internet connection", nil)
                                                          message:NSLocalizedString(@"You currently have no connection to the internet", nil)
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil];
        [alert show];
        return;
    }
    [self getAccess];
}

@end
