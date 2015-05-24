//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import "PCTableViewDataDelegate.h"

@implementation PCTableViewDataDelegate

- (id)initWithTable:(UITableView *)tableView andViewController:(PCViewController *)viewController {
    if ((self = [self init])) {
        self.tableView = tableView;
        self.viewController = viewController;
    }
    return self;
}

- (void)makeActiveDelegateAndRevealFromRight:(BOOL)doRevealRight {
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return nil; //You better override this on a subclass or you deeead
}


@end