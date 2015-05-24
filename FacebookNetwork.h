//
// Created by kylenewsome on 2012-12-22.
//

#import <Foundation/Foundation.h>
#import "Network.h"


@interface FacebookNetwork : Network <UIActionSheetDelegate>
- (void)initializeFacebook;

- (void)handleSetupErrorCode:(NSInteger)code withSuccessSelector:(SEL)selector;
@end