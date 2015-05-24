//
// Created by Kyle Newsome on 2013-09-28.
// Copyright (c) 2013 Kyle Newsome. All rights reserved.
//


#import "ItemAttachmentDetailsCell.h"
#import "PCMessageAttachment.h"
#import "PCMessageMedia.h"
#import "PCMessageLink.h"


@interface ItemAttachmentDetailsCell ()
@property(nonatomic, weak) PCMessageAttachment *attachment;
@property(nonatomic, weak) NSProgress *progressStatus;
@end

@implementation ItemAttachmentDetailsCell

- (void)dealloc {
    if (_progressStatus != nil) {
        [_progressStatus removeObserver:self forKeyPath:@"fractionCompleted"];
        self.progressStatus = nil;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.itemTitleLabel.text = @"";
    self.itemImageView.image = nil;
    self.itemDescriptionLabel.text = @"";
    if (_progressStatus != nil) {
        [_progressStatus removeObserver:self forKeyPath:@"fractionCompleted"];
        self.progressStatus = nil;
    }
    [self.progressView setProgress:0.0f animated:NO];
    self.progressView.alpha = 1.0f;
}

- (void)setWithMessageAttachment:(PCMessageAttachment *)attachment {
    self.attachment = attachment;
    self.itemImageView.image = [[UIImage imageNamed:@"link-image-placeholder"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.itemImageView.tintColor = [PCColorPalette mediumBlueColor];

    if ([attachment isKindOfClass:[PCMessageMedia class]]) {
        if (attachment.progress != nil && attachment.progress.fractionCompleted != 1.0f) {
            // In the process of downloading
            self.itemDescriptionLabel.text = [NSLocalizedString(@"Downloading media...", nil) uppercaseString];
            [attachment.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:nil];
            self.progressStatus = attachment.progress;
            self.progressView.hidden = NO;
            self.progressView.progress = (float) attachment.progress.fractionCompleted;
        } else {
            //ready for full display
            self.progressView.hidden = YES;
            self.itemTitleLabel.text = ([(PCMessageMedia *) _attachment videoData] != nil) ? NSLocalizedString(@"Video", nil) : NSLocalizedString(@"Picture", nil);
            self.itemDescriptionLabel.text = [NSString stringWithFormat:@"Size: %.2f MB",(float)[(PCMessageMedia *) _attachment length]/1024.0f/1024.0f].uppercaseString;
            self.itemImageView.clipsToBounds = YES;
            self.itemImageView.image = [(PCMessageMedia *) attachment image];
        }
    } else if ([attachment isKindOfClass:[PCMessageLink class]]) {
        self.itemImageView.clipsToBounds = YES;
        if (attachment.progress != nil && attachment.progress.fractionCompleted != 1.0f) {
            self.itemTitleLabel.text = [(PCMessageLink *) attachment url] ;
            self.itemDescriptionLabel.text = [NSLocalizedString(@"Attached Link", nil) uppercaseString];
            self.progressView.hidden = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(evaluateParseCompletion) name:@"MessageLinkParsingComplete" object:nil];
        } else {
            self.progressView.hidden = YES;
            if ([(PCMessageLink *) attachment imageURL] != nil) {
                [self.itemImageView setImageWithURL:[NSURL URLWithString:[(PCMessageLink *) attachment imageURL]]];
                self.itemImageView.clipsToBounds = YES;
            }
            self.itemTitleLabel.text = [(PCMessageLink *) attachment title];
            self.itemDescriptionLabel.text = [[(PCMessageLink *) attachment url] uppercaseString];
        }
    }
}

- (IBAction)removeItem {
    if ([self.delegate respondsToSelector:@selector(itemCellDidRequestRemoval:)]) {
        [self.delegate itemCellDidRequestRemoval:self];
    }
}

-(void)evaluateParseCompletion{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MessageLinkParsingComplete" object:nil];
    if(![_attachment isKindOfClass:[PCMessageLink class]]){
        // message links only. Since we reuse attachment cells, it could be displaying a media attachment
        // while a link was parsing in the background that we had been listening for
        // as long as the observer is deregistered, we are all good and the display changes will appear next time
        return;
    }
    [UIView transitionWithView:self duration:0.16f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if ([(PCMessageLink *) _attachment imageURL] != nil) {
            [self.itemImageView setImageWithURL:[NSURL URLWithString:[(PCMessageLink *) _attachment imageURL]]];
            self.itemImageView.clipsToBounds = YES;
        }
        if([(PCMessageLink *) _attachment title] != nil){
            self.itemTitleLabel.text = [(PCMessageLink *) _attachment title];
        }
        if([(PCMessageLink *) _attachment url] != nil){
            self.itemDescriptionLabel.text = [[(PCMessageLink *) _attachment url] uppercaseString];
        }
    } completion:nil];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSProgress *progress = (NSProgress *) object;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:(float) progress.fractionCompleted animated:YES];
        if (progress.fractionCompleted >= 1.0f) {
            BWLog(@"Progress Completed");
            [UIView animateWithDuration:0.8f animations:^{
                self.progressView.alpha = 0.0f;
            }];
            if ([_attachment isKindOfClass:[PCMessageMedia class]]) {
                self.itemTitleLabel.text = ([(PCMessageMedia *) _attachment videoData] != nil) ? NSLocalizedString(@"Video", nil) : NSLocalizedString(@"Picture", nil);
                self.itemDescriptionLabel.text = [NSString stringWithFormat:@"Size: %.2f MB",(float)[(PCMessageMedia *) _attachment length]/1024.0f/1024.0f].uppercaseString;
                self.itemImageView.image = [(PCMessageMedia *) _attachment image];
            }
        }
    });
}

@end