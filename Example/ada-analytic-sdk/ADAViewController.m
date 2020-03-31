//
//  ADAViewController.m
//  ada-analytic-sdk
//
//  Created by chavalit.v@ada-asia.com on 03/31/2020.
//  Copyright (c) 2020 chavalit.v@ada-asia.com. All rights reserved.
//

#import "ADAViewController.h"
@import CoreLocation;
@import CoreBluetooth;

@interface ADAViewController () 

@property(nonatomic, strong) CLLocationManager *locationManager;
    
@end

@implementation ADAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ADAAnalytics sharedInstance].delegate = self;
}

- (IBAction)requestForLocation:(id)sender
{
    [self.locationManager requestWhenInUseAuthorization];
}

- (IBAction)buttonTapEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Button Tap" parameters:@{
        @"Screen Name": @"MainViewController"
    }];
}

- (IBAction)loginEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Login" parameters:@{
        @"Screen Name": @"FBLoginViewController",
        @"UserId": @"12345678",
        @"Platform": @"Facebook"
    }];
}

- (IBAction)purchaseEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Purchase" parameters:@{
        @"Screen Name": @"ProductDetailViewController",
        @"ProductId": @"A12345",
        @"UserId": @"12345678",
        @"Price": @"500",
        @"Currency": @"THB"
    }];
}

- (IBAction)addFriendEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Add Friend" parameters:@{
        @"Screen Name": @"AddFriendViewController",
        @"UserId": @"12345678",
        @"FriendId": @"23423456"
    }];
}

#pragma mark ADAAnalyticsDelegate

- (void)didSuccessLogEventToServer
{
    NSLog(@"Event Logged Succeed");
}

- (void)didFailLogEventToServer:(NSError *)error
{
    NSLog(@"Event Log Failed: %@", error.localizedDescription);
}

@end
