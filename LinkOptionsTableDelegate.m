//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <DBChooser/DBChooser.h>
#import "LinkOptionsTableDelegate.h"
#import "OptionCell.h"

@interface LinkOptionsTableDelegate ()
@property(nonatomic, strong) NSArray *cellInfo;
@end

@implementation LinkOptionsTableDelegate

- (id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController {
    if ((self = [super initWithTable:tableView andViewController:viewController])) {
        self.cellInfo = @[
                @{
                        @"image" : @"keyboard",
                        @"title" : @"Add link to message",
                        @"description" : @"Type in URL",
                        @"selector" : @"addUrl",
                        @"activates" : @YES
                },
                @{
                        @"image" : @"attachment",
                        @"title" : @"Attach link from Dropbox",
                        @"description" : @"Quickly share any file",
                        @"selector" : @"getLinkFromDropbox",
                        @"activates" : @YES
                }
        ];
    }
    return self;
}


- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight {
    [super makeActiveDelegateAndRevealFromRight:doRevealRight];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:(doRevealRight) ? UITableViewRowAnimationLeft : UITableViewRowAnimationRight];
}

- (void)addUrl {
    SDCAlertView *alertView = [[SDCAlertView alloc] initWithTitle:NSLocalizedString(@"Add Link", nil)
                                                          message:NSLocalizedString(@"Type in the URL", nil)
                                                         delegate:self cancelButtonTitle:@"Done"
                                                otherButtonTitles:nil];
    alertView.alertViewStyle = SDCAlertViewStylePlainTextInput;
    [alertView show];
}

- (void)getLinkFromDropbox {
    [[DBChooser defaultChooser] openChooserForLinkType:DBChooserLinkTypePreview
                                    fromViewController:(UIViewController *) self.viewController completion:^(NSArray *results) {
        if ([results count]) {
            DBChooserResult *result = results[0];
            BWLog(@"Name -> %@ \n URL -> %@ \n Size-> %lld \n iconURL -> %@ \n thumbnails -> %@", result.name, result.link.absoluteString, result.size, result.iconURL.absoluteString, result.thumbnails);
            NSString *url = result.link.absoluteString;

            //self.viewController.currentPostcard.url = url;

            PCMessageLink *messageLink = [[PCMessageLink alloc] init];
            messageLink.url = url;
            messageLink.title = result.name;
            messageLink.description = @"Shared from Dropbox";

            if (result.thumbnails.allKeys.count > 0) {
                messageLink.imageURL = [(NSURL *) result.thumbnails[@"200x200"] absoluteString];
            } else {
                messageLink.imageURL = result.iconURL.absoluteString;
            }

            self.viewController.currentPostcard.messageLink = messageLink;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.viewController calculateCharacterCount];
                self.viewController.linkAttachmentIndicator.hidden = NO;
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        } else {
            BWLog(@"cancelled");
            for(OptionCell *cell in [self.tableView visibleCells] ){
                [cell deactivate];
            }
        }
    }];
}

#pragma mark - TableView related

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageLink == nil) {
        NSDictionary *cellInfo = _cellInfo[(NSUInteger) indexPath.row];
        if([cellInfo[@"activates"] boolValue]){
            OptionCell *cell = (OptionCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell activate];
        }
        [self performSelector:NSSelectorFromString(cellInfo[@"selector"]) withObject:nil afterDelay:0.16f];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.viewController.currentPostcard.messageLink != nil) {
        return 1;
    } else {
        return 2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.viewController.currentPostcard.messageLink != nil) {
        return 180.0f;
    } else {
        return 60.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.viewController.currentPostcard.messageLink != nil) {
        PCMessageLink *messageLink = self.viewController.currentPostcard.messageLink;
        ItemAttachmentDetailsCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ItemAttachmentDetailsCell"];
        [cell setWithMessageAttachment:messageLink];
        cell.delegate = self;
        return cell;
    } else {
        NSDictionary *info = _cellInfo[(NSUInteger) indexPath.row];
        OptionCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OptionCell"];
        UIImage *iconImage = [UIImage imageNamed:[NSString stringWithFormat:@"icon-%@", [info valueForKey:@"image"]]];
        cell.iconImageView.image = [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = [PCColorPalette darkBlueColor];
        cell.titleLabel.text = [info valueForKey:@"title"];
        cell.descriptionLabel.text = [[info valueForKey:@"description"] uppercaseString];
        return cell;
    }
}

#pragma mark - ItemAttachmentDetailsCellDelegate
- (void)itemCellDidRequestRemoval:(ItemAttachmentDetailsCell *)cell {
    cell.itemImageView.image = nil;

    NSString *originalUrl = self.viewController.currentPostcard.messageLink.originalUrl;
    if (originalUrl != nil && [self.viewController.postTextView.text rangeOfString:originalUrl].location != NSNotFound) {
        NSString *text = self.viewController.postTextView.text;
        self.viewController.postTextView.text = [text stringByReplacingOccurrencesOfString:self.viewController.currentPostcard.messageLink.originalUrl withString:@""];
    }
    self.viewController.currentPostcard.messageLink = nil;
    self.viewController.linkAttachmentIndicator.hidden = YES;
    [self.viewController calculateCharacterCount];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *url = [alertView textFieldAtIndex:0].text;
    if (url.length > 0) {
        PCMessageLink *messageLink = [[PCMessageLink alloc] init];
        [messageLink setMessageLinkURL:url];
        self.viewController.currentPostcard.messageLink = messageLink;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.viewController calculateCharacterCount];
            self.viewController.linkAttachmentIndicator.hidden = NO;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
    for(OptionCell *cell in [self.tableView visibleCells] ){
        [cell deactivate];
    }
}

@end