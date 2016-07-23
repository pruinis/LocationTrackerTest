//
//  ViewController.h
//  LocationTrackerTest
//
//  Created by Anton Morozov on 23.07.16.
//  Copyright © 2016 Anton Morozov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *modeSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *removeLocBtn;

@end