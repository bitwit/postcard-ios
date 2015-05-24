//
//  PCAppDelegate.h
//  Postcard Beta
//
//  Created by Kyle Newsome on 2013-08-23.
//  Copyright (c) 2013 Kyle Newsome. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability;

@interface PCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic, weak) Reachability *reachChecker;

+(PCAppDelegate *) sharedInstance;

- (NSManagedObjectContext *)managedObjectContext;

- (NSManagedObjectModel *)managedObjectModel;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (NSString *)applicationDocumentsDirectory;

@end
