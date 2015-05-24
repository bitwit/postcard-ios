//
// Created by Kyle Newsome on 11/27/2013.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "HorizontalTableView.h"

typedef enum{
    PCSuggestionSystemViewFilterModeTags = 0,
    PCSuggestionSystemViewFilterModeMentions
} PCSuggestionSystemViewFilterMode;

@class PCSuggestionSystemView;

@protocol PCSuggestionSystemViewDelegate <NSObject>
- (void)suggestionSystemView:(PCSuggestionSystemView *)suggestionSystemView didSelectText:(NSString *)text;
@end

@interface PCSuggestionSystemView : UICollectionView <UICollectionViewDataSource, UICollectionViewDelegate>

@property(nonatomic, weak) IBOutlet id<PCSuggestionSystemViewDelegate>suggestionDelegate;
@property(nonatomic) PCSuggestionSystemViewFilterMode filterMode;

- (void)setText:(NSString *)queryText withFilteringMode:(PCSuggestionSystemViewFilterMode)filterMode;
@end