//
// Created by Kyle Newsome on 12/25/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "SettingsTableDelegate.h"
#import "OptionCell.h"
#import "PCPurchaseHandler.h"
#import "PCTutorialManager.h"

@interface SettingsTableDelegate ()
@property(nonatomic, strong) NSArray *cellInfo;
@end

@implementation SettingsTableDelegate

- (id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController {
    if ((self = [super initWithTable:tableView andViewController:viewController])) {

    }
    return self;
}

- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight {
    [super makeActiveDelegateAndRevealFromRight:doRevealRight];
    [self recalculateCellInfo];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:(doRevealRight) ? UITableViewRowAnimationLeft : UITableViewRowAnimationRight];
}

- (void)recalculateCellInfo {
    NSInteger maxNetworks = [[PCPurchaseHandler sharedInstance] maxAllowedNetworks];
    self.cellInfo = @[
            @{
                    @"image" : @"credits",
                    @"title" : @"Credits & Contact Info",
                    @"description" : @"Hat tips for everyone",
                    @"selector" : @"goToCredits"
            },
            @{
                    @"image" : @"tutorials",
                    @"title" : @"Redisplay tutorial",
                    @"description" : @"Display tutorial alerts again",
                    @"selector" : @"redisplayTutorial"
            },
            (maxNetworks == -1) ? @{
                    @"image" : @"heart",
                    @"title" : @"Thank you for upgrading",
                    @"description" : @"You help support future improvements",
                    @"selector" : @"goToPurchase"
            } : @{
                    @"image" : @"upgrade",
                    @"title" : @"Upgrade Postcard",
                    @"description" : [NSString stringWithFormat:@"Max %d Networks Currently", maxNetworks],
                    @"selector" : @"goToPurchase"
            },
            @{
                    @"image" : @"star",
                    @"title" : @"Rate this app",
                    @"description" : @"A little review goes a long way",
                    @"selector" : @"rateApp"
            },
    ];
}

#pragma mark - Actions

- (void)goToCredits {
    [self.viewController performSegueWithIdentifier:@"pushCredits" sender:self];
}

- (void)goToPurchase {
    NSInteger maxNetworks = [[PCPurchaseHandler sharedInstance] maxAllowedNetworks];
    if (maxNetworks != -1) {
        [self.viewController performSegueWithIdentifier:@"pushPurchase" sender:self];
    }
}

- (void)redisplayTutorial {
    [PCTutorialManager resetTutorial];
}

- (void)rateApp {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/postcard-write-once-share/id589678038?ls=1&mt=8"]];
}

#pragma mark  - TableView related
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageMedia == nil) {
        NSString *selectorName = [_cellInfo[(NSUInteger) indexPath.row] valueForKey:@"selector"];
        [self performSelector:NSSelectorFromString(selectorName)];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellInfo.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *info = _cellInfo[(NSUInteger) indexPath.row];
    OptionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OptionCell"];
    UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", [info valueForKey:@"image"]]];
    cell.iconImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.iconImageView.tintColor = [PCColorPalette darkBlueColor];
    cell.titleLabel.text = [info valueForKey:@"title"];
    cell.descriptionLabel.text = [[info valueForKey:@"description"] uppercaseString];
    return cell;
}

@end