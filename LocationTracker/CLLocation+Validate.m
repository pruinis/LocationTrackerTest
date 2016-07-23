//
//  CLLocation+Validate.m
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import "CLLocation+Validate.h"

@implementation CLLocation (Validate)

+(BOOL)isLocationServiceAvailable
{
    if([CLLocationManager locationServicesEnabled]==NO ||
       [CLLocationManager authorizationStatus]==kCLAuthorizationStatusDenied ||
       [CLLocationManager authorizationStatus]==kCLAuthorizationStatusRestricted){
        return NO;
    }else{
        return YES;
    }
}

+(BOOL)isValidCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (!CLLocationCoordinate2DIsValid(coordinate)){
        return NO;
    }

    if(coordinate.latitude > 90 ||
       coordinate.latitude < -90 ||
       coordinate.longitude > 180 ||
       coordinate.longitude < -180)
    {
        return NO;
    }

    // coordinate is good to use
    return YES;
}



-(BOOL)isValid
{
    // filter out nil locations
    if (!self){
        return NO;
    }

    if (!CLLocationCoordinate2DIsValid(self.coordinate)){
        return NO;
    }

    if(self.coordinate.latitude > 90 ||
       self.coordinate.latitude < -90 ||
       self.coordinate.longitude > 180 ||
       self.coordinate.longitude < -180)
    {
        return NO;
    }

    // newLocation is good to use
    return YES;
}

-(BOOL)isValidRoutePoint
{
    if (![self isValid]) {
        return NO;
    }

    // filter out points by invalid accuracy
    if (self.horizontalAccuracy <= 0 || self.horizontalAccuracy > 100){
        return NO;
    }

    NSTimeInterval locationAge = -[self.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0){
        return NO;
    }

    // newLocation is good to use
    return YES;
}

@end
