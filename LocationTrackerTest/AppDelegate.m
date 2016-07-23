//
//  AppDelegate.m
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import "AppDelegate.h"
#import "LocationTracker.h" 

@interface AppDelegate ()

@property (nonatomic, strong) LocationTracker *locationTracker;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(locationTrackerDidUpdateLocation:)
                                                 name:LocationTrackerDidUpdateLocation
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(locationTrackerDidUpdateLocation:)
                                                 name:LocationTrackerDidUpdateSignificantLocation
                                               object:nil];



    self.locationTracker = [LocationTracker sharedTracker];
    [self.locationTracker didFinishLaunchingWithOptions:launchOptions significantMode:[self locationSignificantMode]];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [self.locationTracker applicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [self.locationTracker applicationDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)locationTrackerDidUpdateLocation:(NSNotification*)notification
{
    CLLocation *lastLocation = [notification object];
    [self addNewLocations:lastLocation];
}


#pragma mark ------------
#pragma mark - Locations

-(NSArray *)locationsArray
{
    NSMutableArray *objectArray;

    NSData *dataRepresentingSavedArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedLocationKey"];
    if (dataRepresentingSavedArray != nil) {
        NSArray *oldSavedArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        if (oldSavedArray != nil)
            objectArray = [[NSMutableArray alloc] initWithArray:oldSavedArray];
        else
            objectArray = [[NSMutableArray alloc] init];
    }

    return objectArray;
}

-(void)addNewLocations:(CLLocation *)location
{
    NSMutableArray *savedPoints = [[NSMutableArray alloc] initWithArray:[self locationsArray]];
    [savedPoints addObject: location];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:savedPoints] forKey:@"SavedLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)removeLocations
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"SavedLocationKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark ------------
#pragma mark - Mode

-(BOOL)locationSignificantMode
{
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"SignificantLocationModeKey"]) {
        return YES;
    }
    return NO;
}

-(void)setLocationSignificantMode:(BOOL)locationSignificantMode
{
    [[NSUserDefaults standardUserDefaults] setBool:locationSignificantMode forKey:@"SignificantLocationModeKey"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
