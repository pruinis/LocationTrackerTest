//
//  LocationTracker.m
//
//  Created by Anton Morozov on 02.07.14.
//  Copyright (c) 2014 Anton Morozov. All rights reserved.
//

#import "LocationTracker.h"
#import "CLLocation+Validate.h"
#import "AppDelegate.h"

NSString* const LocationTrackerDidUpdateLocation = @"LocationTrackerDidUpdateLocation";
NSString* const LocationTrackerDidUpdateSignificantLocation = @"LocationTrackerDidUpdateSignificantLocation";
NSString* const LocationTrackerDidFailWithError = @"LocationTrackerDidFailWithError";

@interface LocationTracker() <CLLocationManagerDelegate>

@end

@implementation LocationTracker {
    BOOL running;
    BOOL appWakeFromLocation;
    CLLocationManager *significantLocationManager;
}

@synthesize lastKnownLocation = _lastKnownLocation;
@synthesize lastKnownHeading = _lastKnownHeading;

+ (LocationTracker*)sharedTracker {
    static dispatch_once_t pred;
    static LocationTracker *locationTrackerSingleton = nil;

    dispatch_once(&pred, ^{
        locationTrackerSingleton = [[self alloc] init];
    });
    return locationTrackerSingleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        running = NO;
        appWakeFromLocation = NO;
        _significantMode = YES;
        _lastKnownLocation = nil;
        _lastKnownHeading = nil;
        _regionRadius = 50.0;
    }
    return self;
}

-(void)setSignificantMode:(BOOL)significantMode
{
    if ([self isInBackground]) return;

    _significantMode = significantMode;

    // Tracker
    [self configManager];

    if (!running) return;

    if (_significantMode) {
        [self restartSignificantLocation];
    } else {
        [self restartAllLocation];
    }
}

-(void)setRegionRadius:(CLLocationDistance)regionRadius
{
    if (regionRadius > 0) {
        _regionRadius = regionRadius;
    } 
}

-(BOOL)isStarted {
    return running;
}

-(void)start {
    if (![CLLocation isLocationServiceAvailable]) {

        if (running) {
            [self stopLocation];
            running = NO;
        }

        // Send notification
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"Authorization status denied" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"com.error.denied" code:1 userInfo:dict];
        [self sendErrorNotification:error];
        return;
    }

    if (running || [self isInBackground]) return;

    [self restartAllLocation];

    running = YES;
}

-(void)stop {
    if (running) {
        [self stopLocation];
        running = NO;
    }

    _lastKnownLocation = nil;
    _lastKnownHeading = nil;
}

-(void)configManager {

    [self stopLocation];

    significantLocationManager = [[CLLocationManager alloc] init];
    significantLocationManager.delegate = self;
    significantLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    significantLocationManager.distanceFilter = 10;
    significantLocationManager.activityType = CLActivityTypeAutomotiveNavigation;

    if (!_significantMode) {
        significantLocationManager.pausesLocationUpdatesAutomatically = NO;

        if (IS_OS_9_OR_LATER) {
            significantLocationManager.allowsBackgroundLocationUpdates = YES;
        } 
    }

    if(IS_OS_8_OR_LATER) {
        [significantLocationManager requestAlwaysAuthorization];
    }
}

-(void)stopLocation {

    if (significantLocationManager) {
        for (CLCircularRegion *oldRegion in [significantLocationManager monitoredRegions]) {
            [significantLocationManager stopMonitoringForRegion:oldRegion];
        }

        [significantLocationManager stopMonitoringSignificantLocationChanges];
        [significantLocationManager stopUpdatingLocation];
        [significantLocationManager stopUpdatingHeading];
    }
}

- (void)restartSignificantLocation {

    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [significantLocationManager startMonitoringSignificantLocationChanges];
    }

    if (!_significantMode && IS_OS_9_OR_LATER) {
        significantLocationManager.allowsBackgroundLocationUpdates = YES;
    }

    if(IS_OS_8_OR_LATER) {
        [significantLocationManager requestAlwaysAuthorization];
    }
}

- (void)restartAllLocation {
    [self stopLocation];

    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [significantLocationManager startMonitoringSignificantLocationChanges];
    }

    [significantLocationManager startUpdatingLocation];
    [significantLocationManager startUpdatingHeading];

    if (!_significantMode && IS_OS_9_OR_LATER) {
        significantLocationManager.allowsBackgroundLocationUpdates = YES;
    }

    if(IS_OS_8_OR_LATER) {
        [significantLocationManager requestAlwaysAuthorization];
    }
}

-(void)addRegionForMonitoring:(CLLocationCoordinate2D)coord toManager:(CLLocationManager*)manager
{
    if ([CLLocation isValidCoordinate:coord] == false) {
        return;
    }

    // check regions, if already have
    for (CLCircularRegion *oldRegion in [manager monitoredRegions]) {
        if ([oldRegion containsCoordinate:coord]) {
            [manager stopMonitoringForRegion:oldRegion];
        }  
    }

    // add new region

    if (_regionRadius > significantLocationManager.maximumRegionMonitoringDistance) {
        _regionRadius = significantLocationManager.maximumRegionMonitoringDistance;
    }

    CLCircularRegion *region = [[CLCircularRegion alloc]initWithCenter:coord radius:_regionRadius identifier:[self genUnicStringName]];
    region.notifyOnEntry = YES;
    region.notifyOnExit = YES;
    [manager startMonitoringForRegion:region];
}

#pragma mark - CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    if (location.isValid == false) return;

    // region monitoring
    if (_significantMode && [self isActive] == false) {
        if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
            [self addRegionForMonitoring:location.coordinate toManager:manager];
        }

        // add location point
        [self addSuspendedLocation:location];
        return;
    }

    // forever location
    if (appWakeFromLocation) {
        [self addSuspendedLocation:location];
        return;
    }

    if (!running) return;

    if (location.isValidRoutePoint) {
        self.lastKnownLocation = [location copy];
        self.lastKnownHeading = [manager.heading copy];
        [self addLocation:[location copy]];
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    if (!running) return;
    self.lastKnownHeading = [newHeading copy];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // Send notification
    [self sendErrorNotification:error];
}

-(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    CLLocation *location = manager.location;
    if (location.isValid == false) return;
    if (_significantMode && [self isActive] == false) {
        [self addSuspendedLocation:location];
    } else {
        [self addLocation:[location copy]];
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    CLLocation *location = manager.location;
    if (location.isValid == false) return;
    [manager stopMonitoringForRegion:region];
    [self addRegionForMonitoring:location.coordinate toManager:manager];
    if (_significantMode && [self isActive] == false) {
        [self addSuspendedLocation:location];
    } else {
        [self addLocation:[location copy]];
    }
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusNotDetermined) {
        if (IS_OS_8_OR_LATER) {
            [significantLocationManager requestAlwaysAuthorization];
        }
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {

        if (!running) return;
        [self restartAllLocation];
    }
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [manager stopMonitoringForRegion:region];
}

#pragma mark - App delegare

- (void)didFinishLaunchingWithOptions:(NSDictionary*)launchOptions significantMode:(BOOL)yes
{
    appWakeFromLocation = NO;

    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        appWakeFromLocation = YES;
        _significantMode = YES;
        [self configManager];
        [self restartSignificantLocation];
    } else { 
        [self setSignificantMode:yes];
    }
}

- (void)applicationDidEnterBackground
{
    if (!running) return;

    if (_significantMode) {
        [self stopLocation];
        [self addRegionForMonitoring:significantLocationManager.location.coordinate toManager:significantLocationManager];
    }

    [self restartSignificantLocation];
}

- (void)applicationDidBecomeActive
{
    appWakeFromLocation = NO;

    if (!running) return;
    [self restartAllLocation];
}

#pragma mark - Helpers

- (BOOL)isInBackground {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

- (BOOL)isActive {
    return [UIApplication sharedApplication].applicationState == UIApplicationStateActive;
}

#pragma mark - Notification

-(void) addLocation:(CLLocation *)location {

    // Send notification
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *aNotification = [NSNotification notificationWithName:LocationTrackerDidUpdateLocation object:[location copy]];
        [[NSNotificationCenter defaultCenter] postNotification:aNotification];
    });
}

-(void)sendErrorNotification:(NSError*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *aNotification = [NSNotification notificationWithName:LocationTrackerDidFailWithError object:[error copy]];
        [[NSNotificationCenter defaultCenter] postNotification:aNotification];
    });
}

-(void)addSuspendedLocation:(CLLocation*)location
{
    // Send notification
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *aNotification = [NSNotification notificationWithName:LocationTrackerDidUpdateSignificantLocation object:[location copy]];
        [[NSNotificationCenter defaultCenter] postNotification:aNotification];
    });
}

-(NSString *)genUnicStringName
{
    NSString *timestampStr = [NSString stringWithFormat:@"%ld", (time_t)[[NSDate date] timeIntervalSince1970]];
    return timestampStr;
}

@end
