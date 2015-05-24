//
//  CreditsViewController.m
//  Postcard App
//
//  Created by Kyle Newsome on 12/25/2013.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "CreditsViewController.h"

@interface CreditsViewController ()

@end

@implementation CreditsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UILabel *labelAppearance = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil];
    [labelAppearance setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
    [labelAppearance setTextColor:[PCColorPalette orangeColor]];
}

- (IBAction)back {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView Delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *titles = [NSArray arrayWithObjects:
            @"Feedback & Feature Requests",
            @"Developed By",
            @"Open Source",
            @"Testing",
            nil
    ];
    return [titles[(NSUInteger) section] uppercaseString];
}
                        /*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 44.0f)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0, tableView.frame.size.width, 44.0f)];
    label.text = [titles[(NSUInteger) section] uppercaseString];
    label.textColor = [PCColorPalette orangeColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
    [headerView addSubview:label];

    return headerView;
}
*/

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0f;
}

@end
