//
//  PCDataDelegate.m
//  AppRewardsClub
//
//  Created by Kyle Newsome on 2012-08-03.
//

#import "PCDataDelegate.h"
#import "NetworkPost.h"
#import "Network.h"
#import "Tag.h"
#import "Person.h"
#import "PDKeychainBindings.h"

@interface PCDataDelegate ()

@end

@implementation PCDataDelegate

// Init
+ (PCDataDelegate *)sharedInstance {
    static PCDataDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PCDataDelegate alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        PCAppDelegate *delegate = (PCAppDelegate *) [[UIApplication sharedApplication] delegate];
        _managedObjectContext = [delegate performSelector:@selector(managedObjectContext)];

        NSBundle *bundle = [NSBundle mainBundle];
        NSString *plistPath = [bundle pathForResource:@"Networks" ofType:@"plist"];

        self.networks = [[NSDictionary alloc] initWithContentsOfFile:plistPath];

        [self loadDefaults];
        [self checkForMigrationsNeeded];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];

    }
    return self;
}

- (void)contextDidSave:(NSNotification *)didSaveNotification {
    NSManagedObjectContext *context = (NSManagedObjectContext *) didSaveNotification.object;
    if (context != _managedObjectContext) {
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:didSaveNotification];
    }
}

#pragma mark -
#pragma mark Defaults and Migration
- (void)loadDefaults {
    if ([[self.fetchedTagsController fetchedObjects] count] != 0) {
        return;
    }
    NSArray *fillerTags = @[
            @"canada"
                    @"coffee",
            @"crazy",
            @"ff",
            @"follow",
            @"followfriday",
            @"interesting",
            @"love",
            @"mlb",
            @"mondays",
            @"music",
            @"news",
            @"nofilter",
            @"nfl",
            @"nhl",
            @"nba",
            @"ontario",
            @"postcard",
            @"quote",
            @"swag",
            @"TGIF",
            @"throwbackthursday",
            @"toronto",
            @"useful"
    ];
    [self handleTagsImport:fillerTags];
}

- (void)checkForMigrationsNeeded {
    //placeholder function for future updates
    /*
	NSManagedObjectContext *context = [self.fetchedPostcardsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedPostcardsController fetchRequest] entity];
     */
}

- (Postcard *)newPostcardFromSocialActivity:(PCSocialActivity *)activity {
    Postcard *postcard = (Postcard *) [NSEntityDescription insertNewObjectForEntityForName:@"Postcard" inManagedObjectContext:_managedObjectContext];
    postcard.message = activity.message;
    postcard.date = [NSDate date];
    postcard.link = activity.messageLink.url;
    postcard.tags = activity.tags;

    if (activity.messageMedia != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *mediaId = [[NSUUID UUID] UUIDString];
        BWLog(@"Documents Directory -> %@", documentsDirectory);
        if (activity.messageMedia.videoData) {
            NSString *videoFilePath = [NSString stringWithFormat:@"%@/%@.mp4", documentsDirectory, mediaId];
            BWLog(@"Writing video to -> %@", videoFilePath);
            [activity.messageMedia.videoData writeToFile:videoFilePath atomically:NO];
            postcard.video = videoFilePath;
        }
        if (activity.messageMedia.imageData) {
            NSString *imageFilePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectory, mediaId];
            BWLog(@"Writing image to -> %@", imageFilePath);
            [activity.messageMedia.imageData writeToFile:imageFilePath atomically:NO];
            postcard.image = imageFilePath;
        }
    }

    for (NSString *key in activity.postIds) {
        NetworkPost *networkPost = (NetworkPost *) [NSEntityDescription insertNewObjectForEntityForName:@"NetworkPost" inManagedObjectContext:_managedObjectContext];
        networkPost.networkId = key;
        networkPost.postId = [NSString stringWithFormat:@"%@", [activity.postIds valueForKey:key]];
        networkPost.postcard = postcard;
    }

    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    return postcard;
}

#pragma mark - Postcard Data Methods
- (NSFetchedResultsController *)fetchedPostcardsController {
    if (_fetchedPostcardsController != nil) {
        return _fetchedPostcardsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Postcard" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:10];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    [NSFetchedResultsController deleteCacheWithName:@"Root"];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedPostcardsController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedPostcardsController performFetch:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }

    return _fetchedPostcardsController;
}

- (NSFetchedResultsController *)fetchAllPostcards {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Postcard" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:10];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    [NSFetchedResultsController deleteCacheWithName:@"Root"];
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
    aFetchedResultsController.delegate = self;
    self.fetchedPostcardsController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedPostcardsController performFetch:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    return _fetchedPostcardsController;
}

#pragma mark - Connected Networks Data Methods

- (NSArray *)getCurrentNetworkReferencesInKeychain {
    PDKeychainBindings *keychainBindings = [PDKeychainBindings sharedKeychainBindings];
    NSString *referenceString = [keychainBindings objectForKey:@"networkReferences"];
    BWLog(@"Reference string -> %@", referenceString);
    NSArray *references = nil;
    if (referenceString != nil) {
        NSError *error = nil;
        references = [NSJSONSerialization JSONObjectWithData:[referenceString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    }
    return references;
}

- (void)storeReferenceToNetworkInKeychain:(Network *)network {
    NSArray *oldReferences = [self getCurrentNetworkReferencesInKeychain];
    NSMutableArray *references = nil;
    if (oldReferences != nil) {
        references = [NSMutableArray arrayWithArray:oldReferences];
    } else {
        references = [NSMutableArray array];
    }

    [references addObject:@{
            @"uuid" : network.UUID,
            @"networkId" : network.name
    }];

    NSError *error = nil;
    NSData *referencesToStore = [NSJSONSerialization dataWithJSONObject:references options:0 error:&error];
    NSString *storableString = [[NSString alloc] initWithData:referencesToStore encoding:NSUTF8StringEncoding];

    PDKeychainBindings *keychainBindings = [PDKeychainBindings sharedKeychainBindings];
    [keychainBindings setObject:storableString forKey:@"networkReferences"];
}

- (void)removeReferenceToNetworkInKeychain:(Network *)network {
    NSArray *oldReferences = [self getCurrentNetworkReferencesInKeychain];
    NSMutableArray *references = nil;
    if (oldReferences == nil)
        return; //no references currently stored

    references = [NSMutableArray arrayWithArray:oldReferences];

    for (int i = references.count - 1; i >= 0; i--) {
        NSDictionary *reference = references[(NSUInteger)i];
        if([reference[@"uuid"] isEqualToString:network.UUID]){
            [references removeObjectAtIndex:(NSUInteger)i];
            break;
        }
    }

    NSError *error = nil;
    NSData *referencesToStore = [NSJSONSerialization dataWithJSONObject:references options:0 error:&error];
    NSString *storableString = [[NSString alloc] initWithData:referencesToStore encoding:NSUTF8StringEncoding];

    PDKeychainBindings *keychainBindings = [PDKeychainBindings sharedKeychainBindings];
    [keychainBindings setObject:storableString forKey:@"networkReferences"];
}


- (NSFetchedResultsController *)fetchedConnectedNetworksController {
    if (_fetchedConnectedNetworksController == nil) {
        return [self createFetchedConnectedNetworksController];
    }
    return _fetchedConnectedNetworksController;
}

- (ConnectedNetwork *)newConnectedNetwork:(Network *)network withTitle:(NSString *)title {
    ConnectedNetwork *connectedNetwork = (ConnectedNetwork *) [NSEntityDescription insertNewObjectForEntityForName:@"ConnectedNetwork" inManagedObjectContext:_managedObjectContext];
    connectedNetwork.networkId = network.name;
    connectedNetwork.instance = network;
    connectedNetwork.title = title;
    connectedNetwork.lastActivated = [NSDate date];
    connectedNetwork.lastDeactivated = [NSDate dateWithTimeIntervalSince1970:0];
    [self storeReferenceToNetworkInKeychain:network];
    return connectedNetwork;
}

- (void)deleteConnectedNetwork:(ConnectedNetwork *)connectedNetwork {
    Network *networkInstance = (Network *)connectedNetwork.instance;
    [self removeReferenceToNetworkInKeychain:networkInstance];
    [networkInstance willDelete];
    [_managedObjectContext deleteObject:connectedNetwork];
}

- (NSFetchedResultsController *)createFetchedConnectedNetworksController {
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ConnectedNetwork" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *hostDescriptor = [[NSSortDescriptor alloc] initWithKey:@"isHost" ascending:NO];
    NSSortDescriptor *enabledDescriptor = [[NSSortDescriptor alloc] initWithKey:@"isEnabled" ascending:NO];
    NSSortDescriptor *lastActivationDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastActivated" ascending:YES];
    NSSortDescriptor *lastDeactivationDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastDeactivated" ascending:NO];
    NSArray *sortDescriptors = @[
            hostDescriptor,
            enabledDescriptor,
            lastActivationDescriptor,
            lastDeactivationDescriptor];

    [fetchRequest setSortDescriptors:sortDescriptors];

    [NSFetchedResultsController deleteCacheWithName:@"ConnectedNetworkCache"];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"ConnectedNetworkCache"];
    aFetchedResultsController.delegate = self;
    self.fetchedConnectedNetworksController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedConnectedNetworksController performFetch:&error]) {
        BWLog(@"Unresolved error fetching ConnectedNetworksController %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    return _fetchedConnectedNetworksController;
}

- (void)saveContext {
    NSError *error = nil;
    if (![_managedObjectContext save:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }

    BWLog(@"Saved Context");
}

#pragma mark - Tags
- (void)handleTagsImport:(NSArray *)tags {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
        PCAppDelegate *appDelegate = (PCAppDelegate *) [[UIApplication sharedApplication] delegate];
        [managedObjectContext setPersistentStoreCoordinator:appDelegate.persistentStoreCoordinator];
        [managedObjectContext setUndoManager:nil];

        // create the fetch request to get all Employees matching the IDs
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Tag" inManagedObjectContext:managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(value IN %@)", tags]];

        // Make sure the results are sorted as well.
        [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES]]];
        // Execute the fetch.
        NSError *error;
        NSArray *matchingTags = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

        NSInteger importCount = 0;
        for (NSString *rawTag in tags) {
            NSString *tag = [rawTag stringByReplacingOccurrencesOfString:@"#" withString:@""];
            Tag *existingTag = nil;
            for (Tag *match in matchingTags) {
                if ([match.value isEqualToString:tag]) {
                    existingTag = match;
                    break;
                }
            }
            if (existingTag == nil) {
                importCount++;
                Tag *newTag = (Tag *) [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectContext];
                newTag.value = tag;
                newTag.lastUsed = [NSDate date];
            } else {
                existingTag.lastUsed = [NSDate date];
            }
        }

        BWLog(@"%d new tags were found, %d tags were updated", importCount, tags.count - importCount);
        // Save the context.
        if (![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        }
    });
}

- (void)filterTagsByString:(NSString *)string {
    [NSFetchedResultsController deleteCacheWithName:@"TagCache"];
    if (string != nil) {
        [_fetchedTagsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(value contains[c] %@)", string]];
    }
    NSError *error = nil;
    if (![_fetchedTagsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (NSFetchedResultsController *)fetchedTagsController {
    if (_fetchedTagsController != nil) {
        return _fetchedTagsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:10];

    // Edit the sort key as appropriate.
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO];
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"value" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateDescriptor, valueDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    [NSFetchedResultsController deleteCacheWithName:@"TagCache"];
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"lastUsed" cacheName:@"TagCache"];
    aFetchedResultsController.delegate = self;
    self.fetchedTagsController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedTagsController performFetch:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    return _fetchedTagsController;
}

#pragma mark - Persons
- (void)handlePersonsImport:(NSArray *)people {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BWLog(@"Handling Persons Import, %d users total", people.count);
        NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
        PCAppDelegate *appDelegate = (PCAppDelegate *) [[UIApplication sharedApplication] delegate];
        [managedObjectContext setPersistentStoreCoordinator:appDelegate.persistentStoreCoordinator];
        [managedObjectContext setUndoManager:nil];

        NSString *idArray = [people valueForKey:@"userId"];

        // create the fetch request to get all Employees matching the IDs
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Person" inManagedObjectContext:managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(userId IN %@)", idArray]];

        // Make sure the results are sorted as well.
        [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"userId" ascending:YES]]];
        // Execute the fetch.
        NSError *error;
        NSArray *matchingPersons = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

        NSInteger importCount = 0;

        for (NSDictionary *person in people) {
            Person *existingPerson = nil;
            for (Person *match in matchingPersons) {
                if ([match.userId isEqualToString:person[@"userId"]]) {
                    existingPerson = match;
                    break;
                }
            }
            if (existingPerson == nil) {
                importCount++;
                Person *newPerson = (Person *) [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:managedObjectContext];
                newPerson.userId = person[@"userId"];
                newPerson.fullName = person[@"fullName"];
                newPerson.username = person[@"username"];
            } else {
                existingPerson.fullName = person[@"fullName"];
                existingPerson.username = person[@"username"];
            }
        }

        BWLog(@"%d new people were found, %d people were updated", importCount, people.count - importCount);
        // Save the context.
        if (![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        }
    });
}

- (void)filterPersonsByString:(NSString *)string {
    [NSFetchedResultsController deleteCacheWithName:@"PersonCache"];
    if (string != nil) {
        [_fetchedPersonsController.fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(username contains[c] %@) OR (fullName contains[c] %@)", string, string]];
    }
    NSError *error = nil;
    if (![_fetchedPersonsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (NSFetchedResultsController *)fetchedPersonsController {
    if (_fetchedPersonsController != nil) {
        return _fetchedPersonsController;
    }
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    // Set the limit to a suitable number.
    [fetchRequest setFetchLimit:10];

    // Edit the sort key as appropriate.
    NSSortDescriptor *dateDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:NO];
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"fullName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateDescriptor, valueDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    [NSFetchedResultsController deleteCacheWithName:@"PersonCache"];
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"username" cacheName:@"PersonCache"];
    aFetchedResultsController.delegate = self;
    self.fetchedPersonsController = aFetchedResultsController;

    NSError *error = nil;
    if (![_fetchedPersonsController performFetch:&error]) {
        BWLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    return _fetchedPersonsController;
}


@end
