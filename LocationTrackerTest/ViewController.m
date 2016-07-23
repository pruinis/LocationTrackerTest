//
//  ViewController.m
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "LocationTracker.h"


@interface ViewController ()<UITableViewDelegate>
{
    NSArray *locationArray;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    AppDelegate *myApp = (AppDelegate *) [[UIApplication sharedApplication]delegate];
    
    _modeSwitch.on = [myApp locationSignificantMode];
    locationArray = [myApp locationsArray];
    [self.tableView reloadData];

    [[LocationTracker sharedTracker] start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)modeDidChanged:(UISwitch *)sender
{
    BOOL on = sender.isOn;
    [LocationTracker sharedTracker].significantMode = on;
    AppDelegate *myApp = (AppDelegate *) [[UIApplication sharedApplication]delegate];
    myApp.locationSignificantMode = on;
}

- (IBAction)removeLocAction:(UIButton *)sender
{
    AppDelegate *myApp = (AppDelegate *) [[UIApplication sharedApplication]delegate];
    [myApp removeLocations];

    locationArray = [myApp locationsArray];
    [self.tableView reloadData];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return locationArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CLLocation *loc = [locationArray objectAtIndex:indexPath.row];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy/MM/dd HH:mm";
    NSString *time = [dateFormatter stringFromDate:loc.timestamp];
    cell.textLabel.text = time; 

    return cell;
}

@end
