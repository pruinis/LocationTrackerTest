//
//  LocationTracker.h
//
//  Created by Anton Morozov on 02.07.14.
//  Copyright (c) 2014 Anton Morozov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// Notification names
extern NSString *const LocationTrackerDidUpdateLocation;
extern NSString *const LocationTrackerDidUpdateSignificantLocation;
extern NSString *const LocationTrackerDidFailWithError;

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_OS_9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) 

@interface LocationTracker : NSObject

+ (LocationTracker*) sharedTracker;

- (BOOL) isStarted;
- (void) start;
- (void) stop;

- (void)didFinishLaunchingWithOptions:(NSDictionary*)launchOptions significantMode:(BOOL)yes;
- (void)applicationDidEnterBackground;
- (void)applicationDidBecomeActive;

@property (nonatomic, copy) CLLocation *lastKnownLocation;
@property (nonatomic, copy) CLHeading *lastKnownHeading;

@property (nonatomic, assign) BOOL significantMode; // defoult Yes
@property (nonatomic, assign) CLLocationDistance regionRadius; // defoult 50 m

@end

