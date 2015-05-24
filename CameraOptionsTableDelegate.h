//
// Created by Kyle Newsome on 2013-09-25.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PCTableViewDataDelegate.h"
#import "PCImagePickerController.h"
#import "OptionCell.h"
#import "ItemAttachmentDetailsCell.h"

@interface CameraOptionsTableDelegate : PCTableViewDataDelegate
        <UIImagePickerControllerDelegate,
        UINavigationControllerDelegate,
        ItemAttachmentDetailsCellDelegate>
@end