//
// Created by Kyle Newsome on 2013-09-28.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>

@class ItemAttachmentDetailsCell;
@class PCMessageAttachment;

@protocol ItemAttachmentDetailsCellDelegate <NSObject>
     -(void)itemCellDidRequestRemoval:(ItemAttachmentDetailsCell *)cell;
@end

@interface ItemAttachmentDetailsCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UIImageView *itemImageView;
@property(nonatomic, weak) IBOutlet UILabel *itemTitleLabel;
@property(nonatomic, weak) IBOutlet UILabel *itemDescriptionLabel;
@property(nonatomic, weak) IBOutlet UIProgressView *progressView;
@property(nonatomic, weak) IBOutlet UIButton *removeButton;

@property(nonatomic, weak) id<ItemAttachmentDetailsCellDelegate> delegate;

-(void)setWithMessageAttachment:(PCMessageAttachment *)attachment;
-(IBAction)removeItem;

@end