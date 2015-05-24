//
// Created by kylenewsome on 2012-12-24.
//

//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class Network;
@class PCSocialActivity;

@protocol NetworksManagerDelegate  <NSObject>
- (void)socialActivity:(PCSocialActivity *)activity didBeginPostingToNetwork:(NSUInteger)index;
- (void)socialActivity:(PCSocialActivity *)activity didCompletePostingToNetwork:(NSUInteger)index;
- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index updatedWithProgress:(double)fraction;
- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index updatedWithMessage:(NSString *)message;
- (void)socialActivity:(PCSocialActivity *)activity postingToNetwork:(NSUInteger)index didFailwithError:(NSError *)error;
- (void)socialActivityComplete:(PCSocialActivity *)activity;
@end

@interface NetworksManager : NSObject

@property(nonatomic, weak) id<NetworksManagerDelegate> delegate;
@property(nonatomic, strong) NSString *documentsDirectory;
@property(nonatomic, weak) UIViewController *rootViewController;
//@property(nonatomic, strong) NSMutableArray *networks; //Array of (Network *)s
@property(nonatomic, strong) PCSocialActivity *currentSocialActivity;
@property(nonatomic) NSUInteger currentNetworkCompletionCount;


+ (NetworksManager *)sharedInstance;
- (void)postActivity:(PCSocialActivity *)activity;
- (void)network:(Network *)network updatedProgress:(double)fraction;
- (void)network:(Network *)network updateMessage:(NSString *)message;
- (void)network:(Network *)network didFailWithError:(NSError *)error;
- (void)network:(Network *)network didCompletePostingWithInfo:(NSDictionary *)info;

@end