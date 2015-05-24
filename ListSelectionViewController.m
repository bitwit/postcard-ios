//
//  ListSelectionViewController.m
//  Postcard
//
//  Created by Kyle Newsome on 2013-09-22.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "ListSelectionViewController.h"
#import "NetworkSetupListSelectionCell.h"

@interface ListSelectionViewController ()
@property(nonatomic, strong) NSArray *options;
@property(nonatomic, strong) NSArray *selection;
@property(nonatomic, weak) NetworkSetupListSelectionCell *setupCell;
@end

@implementation ListSelectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setWithNetworkSetupCell:(NetworkSetupListSelectionCell *)cell andOptions:(NSArray *)options {
   self.options = options;
   self.setupCell = cell;
   self.selection = cell.getValue;
}


- (void)viewWillDisappear:(BOOL)animated {
    NSMutableArray *selection = [NSMutableArray array];
    for (int j = 0; j < _options.count; j++) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:0]];
        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            [selection addObject:@(j)];
        }
    }
    self.selection = selection;
    [_setupCell setSelection:_selection];
}

#pragma mark - UITableViewDelegate / UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return _options.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ListSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.textLabel.text = _options[(NSUInteger) indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryNone;
    for (NSNumber *row in _selection) {
        if (row.integerValue == indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = (cell.accessoryType == UITableViewCellAccessoryNone) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
