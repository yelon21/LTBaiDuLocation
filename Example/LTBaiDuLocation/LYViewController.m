//
//  LYViewController.m
//  LTBaiDuLocation
//
//  Created by yjpal on 10/14/2016.
//  Copyright (c) 2016 yjpal. All rights reserved.
//

#import "LYViewController.h"
#import "LTBaiDuLocation.h"

@interface LYViewController ()

@end

@implementation LYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[LTBaiDuLocation sharedLocation] addObserver:self
                                       forKeyPath:@"currentLocation"
                                          options:NSKeyValueObservingOptionNew
                                          context:nil];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{

    if ([keyPath isEqualToString:@"currentLocation"]) {
        
        BMKLocation *location = change[@"new"];
        NSLog(@"object=%@",[object debugDescription]);
    }
}

- (IBAction)startLocation:(id)sender {
//    [LTBaiDuLocation sharedLocation];
    [[LTBaiDuLocation sharedLocation]lt_startLocation];
}

- (IBAction)checkQX:(id)sender {
    
    NSLog(@"located = %d",[[LTBaiDuLocation sharedLocation] located]);
    NSLog(@"locateEnable = %d",[[LTBaiDuLocation sharedLocation] locateEnable]);
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    NSLog(@"=%@",[[LTBaiDuLocation sharedLocation] debugDescription]);
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
