//
// Created by Kyle Newsome on 2013-09-02.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "NetworkSetupCell.h"

@interface NetworkSetupFieldCell : NetworkSetupCell  <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UILabel *fieldLabel;
@property (nonatomic, weak) IBOutlet UITextField *textField;

@end