//
//  NetworkSetupViewController.m
//  paradigm
//
//  Created by Kyle Newsome on 2012-12-25.
//  Copyright (c) 2012 Kyle Newsome. All rights reserved.
//

#import "NetworkSetupViewController.h"
#import "Network.h"

#import "HorizontalTableView.h"
#import "PCDataDelegate.h"

#import "NetworkSetupManager.h"

#import "OAuth1WebViewController.h"
#import "OAuth2WebViewController.h"

#import "PCStateManager.h"
#import "PCWebViewController.h"
#import "PCTutorialManager.h"

#import "NetworkCollectionViewCell.h"

@interface NetworkSetupViewController ()

@property(nonatomic, weak) PCDataDelegate *dataDelegate;

@property(nonatomic, strong) NSArray *orderedNetworksInfo;
@property(nonatomic, strong) NSDictionary *networkInfo;
@property(nonatomic, strong) Network *socialNetwork;

@property(nonatomic, strong) NetworkSetupManager *networkSetupManager;

@property(nonatomic) BOOL didSetupLoadParameters;

@end

@implementation NetworkSetupViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    [PCStateManager sharedInstance].networkSetupVC = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    BWLog(@"View did load");
    self.dataDelegate = [PCDataDelegate sharedInstance];

    NSArray *networkKeys = _dataDelegate.networks.allKeys;
    NSMutableArray *networkDictionaries = [NSMutableArray array];
    for (NSString *networkName in networkKeys) {
        [networkDictionaries addObject:_dataDelegate.networks[networkName]];
    }
    BWLog(@"Start sorting array");
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    self.orderedNetworksInfo = [networkDictionaries sortedArrayUsingDescriptors:@[descriptor]];
    BWLog(@"Sorted array");

    self.networkSetupManager = [[NetworkSetupManager alloc] initWithSetupViewController:self];
    _networkDetailsTableView.dataSource = _networkSetupManager;
    _networkDetailsTableView.delegate = _networkSetupManager;
    _networkDetailsTableView.contentInset = UIEdgeInsetsMake(10.0f, 0.0f, 0.0f, 0.0f);
    
    _networksCollectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    [self networkAtIndexSelected:0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_didSetupLoadParameters) {
        self.didSetupLoadParameters = YES;
        [self setupWithLoadParameters:_loadParameters];
    }

    if (![PCTutorialManager hasWatchedNetworkSetupTutorial]) {
        [_tutorialView showFromIndex:PCNetworkSetupTutorialStageScrollNetworks];
    }

}

- (void)viewDidDisappear:(BOOL)animated {
    [_tutorialView dismiss];
}

- (IBAction)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setupWithLoadParameters:(NSDictionary *)parameters {
    BWLog(@"View did load");
    self.loadParameters = parameters;
    NSString *loadNetwork = parameters[@"network"];
    NSUInteger i = 0;
    for (NSDictionary *network in _orderedNetworksInfo) {
        if ([network[@"slug"] isEqualToString:loadNetwork]) {
            [self centerTableAtIndex:i];
            [self networkAtIndexSelected:i];
            break;
        }
        i++;
    }
}

- (IBAction)nextTutorialStage {
    NSUInteger index = [_orderedNetworksInfo count] - 1;
    [self centerTableAtIndex:index];
    [self networkAtIndexSelected:index];
}

- (IBAction)dismissTutorial {
    [_tutorialView dismiss];
    [PCTutorialManager setNetworkSetupTutorialAsWatched];
}

- (IBAction)dismissTutorialEarly {
    [_tutorialView dismiss];
    [PCTutorialManager setMainViewTutorialAsWatched];
    [PCTutorialManager setNetworkSetupTutorialAsWatched];
    [PCTutorialManager setNetworkSettingsTutorialAsWatched];
}


- (void)dealloc {
    BWLog(@"NETWORK SETUP VC DEALLOC");
    [PCStateManager sharedInstance].networkSetupVC = nil;
}

- (void)networkAtIndexSelected:(NSUInteger)index {
    self.networkInfo = [_orderedNetworksInfo objectAtIndex:index];
    _networkNameLabel.text = [_networkInfo valueForKey:@"displayName"];
    [_networkSetupManager setupNetworkInfo:_networkInfo];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Make sure your segue name in storyboard is the same as this line
    NSString *identifier = [segue identifier];
    if ([identifier isEqualToString:@"modalOAuth1WebView"] || [identifier isEqualToString:@"modalOAuth2WebView"]) {
        if ([sender respondsToSelector:@selector(webAuthViewSetup:)]) {
            [sender performSelector:@selector(webAuthViewSetup:) withObject:[segue destinationViewController]];
        }
    } else if ([identifier isEqualToString:@"modalWebView"]) {
        PCWebViewController *destVC = segue.destinationViewController;
        destVC.initialURL = [NSURL URLWithString:sender];
    }
}

- (void)centerTableAtIndex:(NSInteger)index {
    [_networksCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

#pragma mark - UICollectionViewDelegate , UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _orderedNetworksInfo.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    CGFloat collectionPadding = (screenSize.width - 64.0f)/2;
    return UIEdgeInsetsMake(0, collectionPadding, 0, collectionPadding);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(64.0f, 64.0f);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //return [collectionView dequeueReusableCellWithReuseIdentifier:@"SimpleCell" forIndexPath:indexPath];
    
    static NSString *identifier = @"NetworkCollectionViewCell";
    NetworkCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        
    NSString *imageName = [NSString stringWithFormat:@"icon-%@.png", _orderedNetworksInfo[(NSUInteger) indexPath.row][@"slug"]];
    cell.icon.image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.icon.tintColor = [PCColorPalette darkBlueColor];
    
    return cell;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self centerTableAtIndex:indexPath.row];
    [self networkAtIndexSelected:(NSUInteger) indexPath.row];
    return YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //if decelerating, let scrollViewDidEndDecelerating: handle it
    [self getRowIndexForCenteredCell];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self getRowIndexForCenteredCell];
}

- (void)getRowIndexForCenteredCell {
    static int cellHeight = 64;
    CGPoint contentOffset = self.networksCollectionView.contentOffset;
    int totalOffset = (int) contentOffset.x + (cellHeight / 2);
    int index = totalOffset / cellHeight;
    int maxIndex = _orderedNetworksInfo.count - 1;
    index = (index >= 0) ? index : 0;
    index = (index <= maxIndex) ? index : maxIndex;
    [self networkAtIndexSelected:(NSUInteger) index];
    [self centerTableAtIndex:(NSUInteger)index];
}

@end
