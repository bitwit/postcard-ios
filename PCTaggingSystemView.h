//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PCTagTextField.h"

@class PCTaggingSystemView;

@protocol PCTaggingSystemViewDelegate <NSObject>
-(void)taggingSystemDidBeginEditingTagField:(PCTaggingSystemView *)taggingSystem;
-(void)taggingSystem:(PCTaggingSystemView *)taggingSystem textForCurrentTag:(NSString *)text;
@end

@interface PCTaggingSystemView : UIScrollView <UITextFieldDelegate, PCTagTextFieldDelegate>

@property(nonatomic, strong) NSMutableArray *tagTextFields;
@property(nonatomic, weak) IBOutlet id<PCTaggingSystemViewDelegate> taggingDelegate;

-(void)setTextForCurrentTag:(NSString *)text;
-(NSArray *)arrayOfTags;
-(NSString *)commaSeparatedTags;
-(void)reset;

@end