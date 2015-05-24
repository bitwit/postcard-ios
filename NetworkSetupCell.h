//
// Created by Kyle Newsome on 2013-09-21.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NetworkSetupCell;

@protocol NetworkSetupCellDelegate <NSObject>
-(void)networkSetupCellDidBeginEditing:(NetworkSetupCell *)cell;
-(void)networkSetupCellDidEndEditing:(NetworkSetupCell *)cell;
-(void)networkSetupCellWillDismissKeyboard:(NetworkSetupCell *)cell;
-(void)networkSetupCellValueDidChange:(NetworkSetupCell *)cell;
-(void)networkSetupCell:(NetworkSetupCell *)cell wantsToVisitURL:(NSString *)urlString;
-(void)networkSetupCellInitiatedSetup:(NetworkSetupCell *)cell;
@end


@interface NetworkSetupCell : UITableViewCell

@property(nonatomic, weak) id <NetworkSetupCellDelegate> delegate;
@property(nonatomic) BOOL isHidingContent;

-(void)setupWithParameters:(NSDictionary *)params andValue:(id)value;
-(CGFloat)height;
-(id)getValue;

@end