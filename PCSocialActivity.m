//
// Created by kylenewsome on 2012-12-25.
//

//


#import "PCSocialActivity.h"
#import "Network.h"

@implementation PCSocialActivity

- (id)init {
    self = [super init];
    if (self) {
        self.networks = [[NSMutableArray alloc] init];
        self.postIds = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithPostcard:(Postcard *)postcard {
    if ((self = [self init])) {
        self.postcard = postcard;
        self.message = postcard.message;
        NSDateFormatter *formatter;
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.date = [formatter stringFromDate:postcard.date];
        self.tags = postcard.tags;

        if (postcard.image != nil) {
            NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:postcard.image]];
            self.messageMedia = [[PCMessageMedia alloc] init];
            self.messageMedia.imageData = imageData;
            if (postcard.video != nil) {
                NSData *videoData = [NSData dataWithContentsOfURL:[NSURL URLWithString:postcard.video]];
                self.messageMedia.videoData = videoData;
            }
        }

        if (postcard.link != nil) {
            self.messageLink = [[PCMessageLink alloc] init];
            [self.messageLink setMessageLinkURL:postcard.link];
        }

    }
    return self;
}

- (void)dealloc {
    BWLog(@"Social Activity deallocating");
}

- (void)addNetwork:(ConnectedNetwork *)network {
    [self.networks addObject:network];
}

- (NSString *)messageWithLink {
    if (self.messageLink != nil) {
        return [NSString stringWithFormat:@"%@ %@", self.message, self.messageLink.url];
    } else {
        return self.message;
    }
}

- (NSString *)messageWithLinkFittingCharacterLimit:(NSUInteger)characterLimit {
    NSString *message = self.message;
    if (self.messageLink != nil) {   //there is a link
        if (message.length > (characterLimit - 23)) { //message alone is too long to accompany link
            message = [[message substringToIndex:(characterLimit - 26)] stringByAppendingString:@"..."];
        }
        return [NSString stringWithFormat:@"%@ %@", message, self.messageLink.url];
    } else if (message.length > characterLimit) { //message is text only but too long (this shouldn't ever occur due to other rules in Postcard, but still here for thoroughness)
        message = [message substringToIndex:characterLimit];
    }
    return message;
}


@end