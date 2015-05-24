//
//  PCDataDelegate.h
//  AppRewardsClub
//
//  Created by Kyle Newsome on 2012-08-03.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Postcard;
@class PCSocialActivity;
@class NetworkPost;
@class NSFetchedResultsController;
@class Network;
@class ConnectedNetwork;

@interface PCDataDelegate : NSObject <NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) NSDictionary *networks;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSFetchedResultsController *fetchedPostcardsController;
@property(nonatomic, strong) NSFetchedResultsController *fetchedConnectedNetworksController;
@property(nonatomic, strong) NSFetchedResultsController *fetchedTagsController;
@property(nonatomic, strong) NSFetchedResultsController *fetchedPersonsController;

+ (PCDataDelegate *) sharedInstance;

#pragma mark -
#pragma mark Defaults and Migration
-(void)loadDefaults;
-(void)checkForMigrationsNeeded;

#pragma mark - Achievements
- (Postcard *)newPostcardFromSocialActivity:(PCSocialActivity *)activity;

-(NSFetchedResultsController *)fetchedPostcardsController;
-(NSFetchedResultsController *)fetchAllPostcards;

-(NSFetchedResultsController *)fetchedConnectedNetworksController;

- (ConnectedNetwork *)newConnectedNetwork:(Network *)network withTitle:(NSString *)title;

- (void)deleteConnectedNetwork:(ConnectedNetwork *)connectedNetwork;

- (NSFetchedResultsController *)createFetchedConnectedNetworksController;

- (void)resortConnectedNetworks;

- (void)updateConnectedNetworkFetchResults;

- (void)saveContext;

//Tags
- (void)handleTagsImport:(NSArray *)tags;
- (void)filterTagsByString:(NSString *)string;
//Persons
- (void)handlePersonsImport:(NSArray *)people;
- (void)filterPersonsByString:(NSString *)string;

@end
