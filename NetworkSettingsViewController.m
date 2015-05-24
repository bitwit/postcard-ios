//
//  NetworkSettingsViewController.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-17.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "NetworkSettingsViewController.h"
#import "Network.h"
#import "NetworkDeleteButtonCell.h"
#import "ConnectedNetwork.h"
#import "ListSelectionViewController.h"
#import "NetworkSetupListSelectionCell.h"
#import "PCLoadingCell.h"
#import "PCTutorialManager.h"
#import "PCDataDelegate.h"

@interface NetworkSettingsViewController ()

@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic, weak) ConnectedNetwork *network;
@property(nonatomic, weak) Network *networkInstance;

@property(nonatomic, strong) NSArray *sections;
@property(nonatomic, strong) NSMutableArray *cells;
@property(nonatomic) BOOL didDeleteNetwork;

@end

@implementation NetworkSettingsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.dataDelegate = [PCDataDelegate sharedInstance];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *labelAppearance = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil];
    [labelAppearance setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
    [labelAppearance setTextColor:[PCColorPalette orangeColor]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setNetworkForSettings:(ConnectedNetwork *)network {
    self.network = network;
    self.sections = nil;
    self.cells = [NSMutableArray arrayWithObject:[NSMutableArray array]];
}

-(IBAction)back{
    [_tutorialView dismiss];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)dismissTutorialEarly {
    [_tutorialView dismiss];
    [PCTutorialManager setMainViewTutorialAsWatched];
    [PCTutorialManager setNetworkSetupTutorialAsWatched];
    [PCTutorialManager setNetworkSettingsTutorialAsWatched];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (![PCTutorialManager hasWatchedNetworkSettingsTutorial]) {
        [_tutorialView show];
        [PCTutorialManager setNetworkSettingsTutorialAsWatched];
    }

    self.networkInstance = (Network *)_network.instance;

    if(_sections == nil){
        self.sections = @[ //table
                @[ //section
                        @{  //field
                                @"type" : @"Field",
                                @"title" : NSLocalizedString(@"title", nil),
                                @"property" : @"title",
                                @"owner" : @"data"
                        }
                ]
        ];
        self.sections = [_sections arrayByAddingObjectsFromArray:_networkInstance.settingFields];

        [self.tableView beginUpdates];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

        NSUInteger i = 0;
        for (NSArray *section in _sections) {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:i] withRowAnimation:UITableViewRowAnimationFade];
            NSUInteger j = 0;
            for (NSDictionary *field in section) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                [self configureNetworkSetupCellAtIndexPath:indexPath];
                j++;
            }
            i++;
        }
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:_sections.count] withRowAnimation:UITableViewRowAnimationFade]; //Delete Button section

        [self.tableView endUpdates];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!_didDeleteNetwork) {
        //Saving network info
        NSUInteger s = 0;
        for (NSArray *fields in _sections) {
            NSUInteger r = 0;
            for (NSDictionary *field in fields) {
                NetworkSetupCell *cell = (NetworkSetupCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:r inSection:s]];
                BWLog(@"%@ - %@", cell, cell.getValue);
                if ([[field valueForKey:@"owner"] isEqualToString:@"data"]) {
                    [_network setValue:cell.getValue forKey:[field valueForKey:@"property"]];
                } else {
                    [_networkInstance setValue:cell.getValue forKey:[field valueForKey:@"property"]];
                    BWLog(@"Instance %@ setting %@ to %@", _networkInstance, [field valueForKey:@"property"], cell.getValue);
                }
                r++;
            }
            s++;
        }
        //Need to create a new instance so core data knows to save what's inside
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:_networkInstance forKey:@"network"];
        [archiver finishEncoding];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        Network *newInstance = [unarchiver decodeObjectForKey:@"network"];
        [_network setInstance:newInstance];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BWLog(@"identifier -> %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"pushSelectionDetails"]) {
        ListSelectionViewController *listSelectionViewController = (ListSelectionViewController *) segue.destinationViewController;
        NSIndexPath *indexPath = (NSIndexPath *) sender;
        NSDictionary *field = _sections[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        NSArray *data = [field valueForKey:@"dataSource"];
        NetworkSetupListSelectionCell *cell = (NetworkSetupListSelectionCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        [listSelectionViewController setWithNetworkSetupCell:cell andOptions:data];
    }
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_sections == nil) return 1; //loading
    return _sections.count + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 36.0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (_sections == nil) {
        return nil;
    } else if (section == _sections.count) {
        return [NSLocalizedString(@"Delete Network", nil) uppercaseString];
    } else {
        NSArray *fields = [_sections objectAtIndex:(NSUInteger) section];
        return [[fields[0] valueForKey:@"title"] uppercaseString];
    }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    if (_sections == nil) {
        return 1; //loading
    } else if (_sections.count == section) {
        return 1;
    } else {
        NSArray *fields = [_sections objectAtIndex:(NSUInteger) section];
        return fields.count;
    }
}

- (NetworkSetupCell *)configureNetworkSetupCellAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < _cells.count) {
        if (indexPath.row < [_cells[(NSUInteger) indexPath.section] count]) {
            return _cells[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        }
    } else {
        [_cells addObject:[NSMutableArray array]];
    }

    NSArray *fields = [_sections objectAtIndex:(NSUInteger) indexPath.section];
    NSDictionary *field = [fields objectAtIndex:(NSUInteger) indexPath.row];
    NSString *cellIdentifier = [NSString stringWithFormat:@"NetworkSetup%@Cell", [field valueForKey:@"type"]];

    BWLog(@"Configuring new cell for s:%d r:%d id: %@", indexPath.section, indexPath.row, cellIdentifier);

    NetworkSetupCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.delegate = self;
    id value;
    if ([[field valueForKey:@"owner"] isEqual:@"data"]) {
        value = [self.network valueForKey:[field valueForKey:@"property"]];
    } else {
        value = [self.networkInstance valueForKey:[field valueForKey:@"property"]];
    }
    [cell setupWithParameters:field andValue:value];

    [self evaluateShowConditions:[field valueForKey:@"showConditions"] forCell:cell];
    [_cells[(NSUInteger) indexPath.section] addObject:cell];

    return cell;
}

- (void)evaluateShowConditions:(NSDictionary *)conditions forCell:(NetworkSetupCell *)cell {
    if (conditions) {
        BOOL areConditionsMet = YES;
        for (NSString *fieldName in conditions.allKeys) {
            id fieldValue = [conditions valueForKey:fieldName];
            id currentValue = [self.networkInstance valueForKey:fieldName];
            //BWLog(@"show condition -- %@ = %@ : %d", fieldValue, currentValue, [fieldValue isEqual:currentValue]);
            if (![fieldValue isEqual:currentValue]) {
                areConditionsMet = NO;
            }
        }
        cell.isHidingContent = !areConditionsMet;
    } else {
        cell.isHidingContent = NO;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == _sections.count) {
        return 100.0f; //delete button
    } else {
        NetworkSetupCell *cell = [self configureNetworkSetupCellAtIndexPath:indexPath];
        CGFloat height = [cell height];
        return height;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(_sections == nil){
        static NSString *loadingCellIdentifier = @"LoadingCell";
        PCLoadingCell *cell = [self.tableView dequeueReusableCellWithIdentifier:loadingCellIdentifier];
        [cell.activityIndicator startAnimating];
        return cell;
    }

    static NSString *deleteButtonIdentifier = @"NetworkDeleteButtonCell";
    if (indexPath.section == _sections.count) {
        NetworkDeleteButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:deleteButtonIdentifier];
        cell.activityIndicator.hidden = YES;
        return cell;
    } else {
        return [self configureNetworkSetupCellAtIndexPath:indexPath];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == _sections.count) {
        [_dataDelegate deleteConnectedNetwork:_network];
        self.didDeleteNetwork = YES;
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSDictionary *field = _sections[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
        if ([[field valueForKey:@"type"] isEqualToString:@"ListSelection"]) {
            [self performSegueWithIdentifier:@"pushSelectionDetails" sender:indexPath];
        }
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - NetworkSetupCellDelegate

- (void)networkSetupCellValueDidChange:(NetworkSetupCell *)cell {
    [self performSelector:@selector(evaluateChangesForCell:) withObject:cell afterDelay:0.01f];
}

#pragma mark - Performance improvement

- (void)evaluateChangesForCell:(NetworkSetupCell *)cell {
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    NSDictionary *field = _sections[(NSUInteger) indexPath.section][(NSUInteger) indexPath.row];
    NSString *propertyName = [field valueForKey:@"property"];

    if ([[field valueForKey:@"owner"] isEqualToString:@"data"]) {
        [_network setValue:cell.getValue forKey:propertyName];
    } else {
        [_networkInstance setValue:cell.getValue forKey:propertyName];
    }

    NSMutableArray *updateIndexes = [NSMutableArray array];
    if ([field valueForKey:@"relatedFields"]) {
        for (NSString *relatedFieldName in [field valueForKey:@"relatedFields"]) {
            NSUInteger rowIndex = 0;
            for (NSDictionary *relatedField in _sections[(NSUInteger) indexPath.section]) {
                if ([[relatedField valueForKey:@"property"] isEqualToString:relatedFieldName]) {
                    //NetworkSetupCell *relatedCell = _cells[(NSUInteger) indexPath.section][rowIndex];
                    //[self evaluateShowConditions:[relatedField valueForKey:@"showConditions"] forCell:relatedCell];
                    [_cells[(NSUInteger) indexPath.section] removeObjectAtIndex:rowIndex];
                    [updateIndexes addObject:[NSIndexPath indexPathForRow:rowIndex inSection:indexPath.section]];
                }
                rowIndex++;
            }
        }
    }

    [_tableView reloadRowsAtIndexPaths:updateIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
