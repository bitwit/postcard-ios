//
// Created by kylenewsome on 2012-12-25.
//

//


#import <Foundation/Foundation.h>
#import "PCMessageLink.h"
#import "PCMessageMedia.h"
#import "Postcard.h"
#import "ConnectedNetwork.h"

@interface PCSocialActivity : NSObject

@property(nonatomic, weak) Postcard *postcard;
@property(nonatomic, strong) NSMutableArray *networks;
@property(nonatomic, strong) NSString *date;
@property(nonatomic, strong) NSString *message;
@property(nonatomic, strong) NSString *tags;
@property(nonatomic, strong) PCMessageLink *messageLink;
@property(nonatomic, strong) PCMessageMedia *messageMedia;
@property(nonatomic, strong) NSMutableDictionary *postIds; //ids of the posts on various social networksManager

@property(nonatomic) BOOL isFromAHost;
@property(nonatomic, strong) NSString *hostId;
@property(nonatomic) Networks hostNetwork;

-(id)initWithPostcard:(Postcard *)postcard;
- (void)addNetwork:(ConnectedNetwork *)network;
- (NSString *)messageWithLink;
- (NSString *)messageWithLinkFittingCharacterLimit:(NSUInteger)characterLimit;

@end