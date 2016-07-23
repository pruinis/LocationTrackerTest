//
//  CLLocation+Validate.h
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocation (Validate)

+(BOOL)isLocationServiceAvailable;
+(BOOL)isValidCoordinate:(CLLocationCoordinate2D)coordinate;

-(BOOL)isValid;
-(BOOL)isValidRoutePoint;

@end
