//
//  AppDelegate.h
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) BOOL locationSignificantMode;

-(NSArray *)locationsArray;
-(void)removeLocations;

@end

