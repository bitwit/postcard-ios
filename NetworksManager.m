//
// Created by kylenewsome on 2012-12-24.
//


#import "NetworksManager.h"
#import "PCSocialActivity.h"
#import "PCDataDelegate.h"
#import "ConnectedNetwork.h"
#import "Network.h"

@interface NetworksManager ()

@property(nonatomic, strong) ConnectedNetwork *currentNetwork;
@property(nonatomic, weak) PCDataDelegate *dataDelegate;
@property(nonatomic, weak) NSFetchedResultsController *connectedNetworksController;
@property(nonatomic) BOOL isInHostingMode;

@end

@implementation NetworksManager

+ (NetworksManager *)sharedInstance {
    static NetworksManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NetworksManager alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        self.dataDelegate = [PCDataDelegate sharedInstance];
        self.connectedNetworksController = _dataDelegate.fetchedConnectedNetworksController;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.documentsDirectory = [paths objectAtIndex:0];
    }
    return self;
}

- (NSUInteger)indexForNetwork:(Network *)network {
    NSUInteger index = 0;
    for (ConnectedNetwork *connectedNetwork in _currentSocialActivity.networks) {
        if ((Network *) connectedNetwork.instance == network) {
            return index;
        }
        index++;
    }
    @throw [NSException exceptionWithName:@"Network not found" reason:@"Network not found in array" userInfo:nil];
}

- (void)postActivity:(PCSocialActivity *)activity {
    BWLog(@"Posting to %d networks", [activity.networks count]);
    self.currentNetworkCompletionCount = 0;
    self.currentSocialActivity = activity;
    NSUInteger index = 0;

    self.isInHostingMode = ([(ConnectedNetwork *) _currentSocialActivity.networks[0] isHost].boolValue);

    if (_isInHostingMode) {
        ConnectedNetwork *hostNetwork = (ConnectedNetwork *) _currentSocialActivity.networks[0];
        Network *network = (Network *) hostNetwork.instance;
        [self.delegate socialActivity:_currentSocialActivity didBeginPostingToNetwork:index];
        @try {
            [network postUpdate:_currentSocialActivity];
        }
        @catch (NSException *e) {
            BWLog(@"Exception -> %@", e);
            NSError *error = [NSError errorWithDomain:@"Activity Posting Error" code:400 userInfo:nil];
            self.currentNetworkCompletionCount++;
            [self.delegate socialActivity:_currentSocialActivity postingToNetwork:index didFailwithError:error];
            [self evaluateNextOption];
        }
    } else {
        for (ConnectedNetwork *connectedNetwork in _currentSocialActivity.networks) {
            Network *network = (Network *) connectedNetwork.instance;
            [self.delegate socialActivity:_currentSocialActivity didBeginPostingToNetwork:index];
            @try {
                BWLog(@"Posting to new network -> %@", [network name])
                [network postUpdate:_currentSocialActivity];
            }
            @catch (NSException *e) {
                BWLog(@"Exception -> %@", e);
                NSError *error = [NSError errorWithDomain:@"Activity Posting Error" code:400 userInfo:nil];
                self.currentNetworkCompletionCount++;
                [self.delegate socialActivity:_currentSocialActivity postingToNetwork:index didFailwithError:error];
                [self evaluateNextOption];
            }
            index++;
        }
    }
}

- (void)network:(Network *)network updatedProgress:(double)fraction {
    BWLog(@"");
    [self.delegate socialActivity:_currentSocialActivity postingToNetwork:[self indexForNetwork:network] updatedWithProgress:fraction];
}

- (void)network:(Network *)network updateMessage:(NSString *)message {
    BWLog(@"%@", message);
    [self.delegate socialActivity:_currentSocialActivity postingToNetwork:[self indexForNetwork:network] updatedWithMessage:message];
}

- (void)network:(Network *)network didFailWithError:(NSError *)error {
    BWLog(@"");
    self.currentNetworkCompletionCount++;
    [self.delegate socialActivity:_currentSocialActivity postingToNetwork:[self indexForNetwork:network] didFailwithError:error];
    [self evaluateNextOption];
}

- (void)network:(Network *)network didCompletePostingWithInfo:(NSDictionary *)info {
    BWLog(@"info -> %@", info);
    if (_isInHostingMode && _currentNetworkCompletionCount == 0) {
        //host completed and has a permalink for us
        PCMessageLink *link = [[PCMessageLink alloc] init];
        link.url = info[@"permalink"];
        link.title = _currentSocialActivity.message;
        NSDateFormatter *inFormat = [[NSDateFormatter alloc] init];
        [inFormat setDateFormat:@"MMM dd, yyyy"];
        link.description = @"Posted on %@", [inFormat stringFromDate:[NSDate date]];
        _currentSocialActivity.messageLink = link;
        _currentSocialActivity.isFromAHost = YES;
        _currentSocialActivity.hostId = info[@"id"];
        _currentSocialActivity.hostNetwork = network.tag;
    }
    //BWLog(@"%@ finished posting. networkIndex %d || totalNetworks %d", network.name, [self indexForNetwork:network], [_currentSocialActivity.networks count]);
    self.currentNetworkCompletionCount++;
    [self.delegate socialActivity:_currentSocialActivity didCompletePostingToNetwork:[self indexForNetwork:network]];
    [self evaluateNextOption];
}

- (void)evaluateNextOption {
    if (_isInHostingMode && _currentNetworkCompletionCount == 1) {
        //host just completed, prepare remaining networks
        for (NSUInteger i = 1; i < _currentSocialActivity.networks.count; i++) {
            ConnectedNetwork *connectedNetwork = _currentSocialActivity.networks[i];
            Network *network = (Network *) connectedNetwork.instance;
            [self.delegate socialActivity:_currentSocialActivity didBeginPostingToNetwork:i];
            @try {
                BWLog(@"Posting to new network -> %@", [network name])
                [network postUpdate:_currentSocialActivity];
            }
            @catch (NSException *e) {
                BWLog(@"Exception -> %@", e);
                NSError *error = [NSError errorWithDomain:@"Activity Posting Error" code:400 userInfo:nil];
                self.currentNetworkCompletionCount++;
                [self.delegate socialActivity:_currentSocialActivity postingToNetwork:i didFailwithError:error];
                [self evaluateNextOption];
            }
        }
    }

    if (_currentNetworkCompletionCount >= [_currentSocialActivity.networks count]) {
        BWLog(@"Posting activities completed");
        //[_dataDelegate newPostcardFromSocialActivity:_currentSocialActivity];
        self.currentNetwork = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate socialActivityComplete:self.currentSocialActivity];
        });
    }
}

@end