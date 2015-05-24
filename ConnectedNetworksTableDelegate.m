//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "PostcardNetworkCell.h"
#import "ConnectedNetworksTableDelegate.h"
#import "PCDataDelegate.h"
#import "AddNetworkTableViewCell.h"
#import "Network.h"
#import "PCPurchaseHandler.h"
#import "PCTutorialManager.h"

@interface ConnectedNetworksTableDelegate ()
@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic, copy) NSIndexPath *addedNetworkIndex;
@property(nonatomic) BOOL isCurrentlySwipingCell;
@end

@implementation ConnectedNetworksTableDelegate

- (id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController {
    if ((self = [super initWithTable:tableView andViewController:viewController])) {
        self.dataDelegate = [PCDataDelegate sharedInstance];
    }
    return self;
}

- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight {
    [super makeActiveDelegateAndRevealFromRight:doRevealRight];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:(doRevealRight) ? UITableViewRowAnimationLeft : UITableViewRowAnimationRight];
    _dataDelegate.fetchedConnectedNetworksController.delegate = self;
}

#pragma mark - Fetched Results Controller
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    //BWLog(@"\nsection: %@ \nidxPath: %d \nchangeType: %d \n\n", sectionInfo, sectionIndex, type);
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    // BWLog(@"\nobj: %@ \nidxPath: %@ \nchangeType: %d \nnewIdxPath: %@ \n\n", anObject, indexPath, type, newIndexPath);
    switch (type) {
        case NSFetchedResultsChangeInsert: {

            if (self.viewController.tableStatus == kTableViewStatusNetworks) {
                self.addedNetworkIndex = newIndexPath;
                [self.tableView insertRowsAtIndexPaths:@[_addedNetworkIndex] withRowAnimation:UITableViewRowAnimationNone];
            }
            //only do this animation if we are ont he networks table. given url load paramater functionality, this isnt guaranteed
        }
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate: {
            if (newIndexPath) {
                [self configureNetworkCell:(PostcardNetworkCell *) [tableView cellForRowAtIndexPath:indexPath] forIndexPath:newIndexPath];
                [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            } else {
                [UIView animateWithDuration:0.34f animations:^{
                    [self configureNetworkCell:(PostcardNetworkCell *) [tableView cellForRowAtIndexPath:indexPath] forIndexPath:indexPath];
                }];
            }
            break;
        }
        case NSFetchedResultsChangeMove:
            [self configureNetworkCell:(PostcardNetworkCell *) [tableView cellForRowAtIndexPath:indexPath] forIndexPath:newIndexPath];
            [tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    BWLog(@"");
    [self.viewController updateNetworkCount];
    [self.tableView endUpdates];
    if (_addedNetworkIndex != nil) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_addedNetworkIndex];
        [self.tableView scrollToRowAtIndexPath:_addedNetworkIndex atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        [self performSelector:@selector(highlightAddedNetwork) withObject:nil afterDelay:0.10f];
    }
    [_dataDelegate saveContext];
}

- (void)highlightAddedNetwork {
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[_addedNetworkIndex] withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView insertRowsAtIndexPaths:@[_addedNetworkIndex] withRowAnimation:UITableViewRowAnimationRight];
    [self.tableView endUpdates];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_addedNetworkIndex];
    [cell setHighlighted:YES animated:NO];
    [self performSelector:@selector(dismissAddedNetworkHighlight) withObject:nil afterDelay:0.86f];
}

- (void)dismissAddedNetworkHighlight {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_addedNetworkIndex];
    [cell setHighlighted:NO animated:YES];
    self.addedNetworkIndex = nil;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NOTE: the bottom row (add button) is managed directly as a push form the segue
    //If this is the bottom row, then display network setup view
    if (indexPath.row != (_dataDelegate.fetchedConnectedNetworksController.fetchedObjects.count)) {
        ConnectedNetwork *network = [_dataDelegate.fetchedConnectedNetworksController.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
        network.isEnabled = @(1 - network.isEnabled.boolValue);
        if (network.isEnabled.boolValue) {
            network.lastActivated = [NSDate date];
        } else {
            network.lastActivated = [NSDate dateWithTimeIntervalSince1970:0];
            network.lastDeactivated = [NSDate date];
            if (network.isHost.boolValue) {
                [(PostcardNetworkCell *) [tableView cellForRowAtIndexPath:indexPath] setIsHost:NO animated:YES];
            }
            network.isHost = @NO;
        }
        [self.viewController updateNetworkCount];

        if (![PCTutorialManager hasWatchedMainViewTutorial] && self.viewController.tutorialStage == PCMainViewTutorialStageTapEnable) {
            [self.viewController performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageSwipeSettings) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
        }

    } else {
        PCPurchaseHandler *purchaseHandler = [PCPurchaseHandler sharedInstance];
        NSInteger maxNetworks = purchaseHandler.maxAllowedNetworks;
        if (maxNetworks != -1 && _dataDelegate.fetchedConnectedNetworksController.fetchedObjects.count >= maxNetworks) {
            [self.viewController performSegueWithIdentifier:@"pushPurchase" sender:self];
        } else {
            [self.viewController performSegueWithIdentifier:@"pushNetworkSetup" sender:self];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataDelegate.fetchedConnectedNetworksController.fetchedObjects.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *connectedNetworkCellIdentifier = @"PostcardNetworkCell";
    static NSString *newNetworkCellIdentifier = @"AddNewNetworkCell";
    if (indexPath.row == (_dataDelegate.fetchedConnectedNetworksController.fetchedObjects.count)) {
        AddNetworkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:newNetworkCellIdentifier];
        return cell;
    } else {
        PostcardNetworkCell *cell = [tableView dequeueReusableCellWithIdentifier:connectedNetworkCellIdentifier];
        [self configureNetworkCell:cell forIndexPath:indexPath];
        return cell;
    }
}

- (void)configureNetworkCell:(PostcardNetworkCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    ConnectedNetwork *network = [_dataDelegate.fetchedConnectedNetworksController.fetchedObjects objectAtIndex:(NSUInteger) indexPath.row];
    cell.networkNameLabel.text = network.title;
    cell.networkTypeLabel.text = [[[_dataDelegate.networks valueForKey:network.networkId] valueForKey:@"displayName"] uppercaseString];

    if (!network.isEnabled.boolValue) {
        cell.tintColor = [UIColor grayColor];
        cell.enabledIndicatorImageView.image = [[UIImage imageNamed:@"icon-disabled-network"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.networkTypeLabel.tintColor = [UIColor lightGrayColor];
        UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", network.networkId]];
        cell.networkImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        cell.tintColor = [PCColorPalette darkBlueColor];
        cell.enabledIndicatorImageView.image = [[UIImage imageNamed:@"icon-enabled-network"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.networkTypeLabel.tintColor = [PCColorPalette lightBlueColor];
        UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", network.networkId]];
        cell.networkImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }

    cell.networkNameLabel.textColor = cell.networkNameLabel.highlightedTextColor = cell.networkImageView.tintColor = cell.enabledIndicatorImageView.tintColor = cell.tintColor;
    cell.networkTypeLabel.textColor = cell.networkTypeLabel.highlightedTextColor = cell.networkTypeLabel.tintColor;

    cell.delegate = self;
    cell.isHost = network.isHost.boolValue;
    cell.canHost = [(Network *) network.instance canHostContent];
}

#pragma mark - RMSwipeTableViewCellDelegate
- (void)swipeTableViewCellDidStartSwiping:(RMSwipeTableViewCell *)swipeTableViewCell {
    if (!_isCurrentlySwipingCell) {
        self.isCurrentlySwipingCell = YES;
        for (UITableViewCell *cell in [self.tableView visibleCells]) {
            if ([cell isKindOfClass:[PostcardNetworkCell class]] && cell != swipeTableViewCell) {
                [(PostcardNetworkCell *) cell setRevealDirection:RMSwipeTableViewCellRevealDirectionNone];
            }
        }
    }
}

- (void)swipeTableViewCellWillResetState:(RMSwipeTableViewCell *)swipeTableViewCell fromPoint:(CGPoint)point animation:(RMSwipeTableViewCellAnimationType)animation velocity:(CGPoint)velocity {
    BWLog(@"%@", swipeTableViewCell);
    NSIndexPath *indexPath = [self.tableView indexPathForCell:swipeTableViewCell];
    if (point.x < 0 && -point.x >= CGRectGetHeight(swipeTableViewCell.frame)) {
        //Go to settings for this network
        [self.viewController performSegueWithIdentifier:@"pushSettings" sender:indexPath];
    } else if (point.x > 0 && point.x >= CGRectGetHeight(swipeTableViewCell.frame)) {
        //Go to feed view for this currentNetworkInstance
        NSArray *connectedNetworks = _dataDelegate.fetchedConnectedNetworksController.fetchedObjects;
        ConnectedNetwork *thisNetwork = connectedNetworks[(NSUInteger) indexPath.row];
        NSUInteger index = 0;
        if ([(Network *) thisNetwork.instance canHostContent]) {
            for (ConnectedNetwork *network in connectedNetworks) {
                if (network == thisNetwork) {
                    network.isHost = @(!network.isHost.boolValue);
                    if (![PCTutorialManager hasWatchedMainViewTutorial]) {
                        if (network.isHost.boolValue && self.viewController.tutorialStage == PCMainViewTutorialStageSwipeHost) {
                            [self.viewController performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageSwipeDisableHost) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
                        }
                        else if (!network.isHost.boolValue && self.viewController.tutorialStage == PCMainViewTutorialStageSwipeDisableHost) {
                            [self.viewController performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageMediaButton) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
                        }
                    }

                } else {
                    if (network.isHost.boolValue) {
                        PostcardNetworkCell *cell = (PostcardNetworkCell *) [self.viewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
                        [cell setIsHost:NO animated:YES];
                    }
                    network.isHost = @NO;
                }
                index++;
            }
            PostcardNetworkCell *cell = (PostcardNetworkCell *) swipeTableViewCell;
            [cell setIsHost:thisNetwork.isHost.boolValue animated:YES];

            if (!thisNetwork.isEnabled.boolValue) {
                thisNetwork.isEnabled = @YES;
                thisNetwork.lastActivated = [NSDate date];
            }

        } else {
            NSString *message = [NSString stringWithFormat:@"%@ networks can't host content", [[(Network *) thisNetwork.instance name] capitalizedString]];

            SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"Can't use this network \nas a host", nil)
                                                                  message:message
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
            alertView.tintColor = [PCColorPalette darkBlueColor];
            [alertView show];

            if (![PCTutorialManager hasWatchedMainViewTutorial]) {
                //letting them pass anyway
                if (self.viewController.tutorialStage == PCMainViewTutorialStageSwipeHost) {
                    [self.viewController performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageSwipeDisableHost) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
                }
                else if (self.viewController.tutorialStage == PCMainViewTutorialStageSwipeDisableHost) {
                    [self.viewController performSelector:@selector(showTutorial:) withObject:@(PCMainViewTutorialStageMediaButton) afterDelay:MAIN_VIEW_TUTORIAL_SHOW_DELAY];
                }
            }

        }
    }
}

- (void)swipeTableViewCellDidResetState:(RMSwipeTableViewCell *)swipeTableViewCell fromPoint:(CGPoint)point animation:(RMSwipeTableViewCellAnimationType)animation velocity:(CGPoint)velocity {
    self.isCurrentlySwipingCell = NO;
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        if ([cell isKindOfClass:[PostcardNetworkCell class]]) {
            [(PostcardNetworkCell *) cell setRevealDirection:RMSwipeTableViewCellRevealDirectionBoth];
        }
    }
}

@end