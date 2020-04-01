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

- (IBAction)onWelcomeTap:(id)sender
{
    [self.locationManager requestWhenInUseAuthorization];
}

- (IBAction)registerTapEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Register" parameters:@{
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

- (IBAction)qrCodeEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"QR Code" parameters:@{
        @"Screen Name": @"ProductDetailViewController",
        @"ProductId": @"A12345",
        @"UserId": @"12345678",
        @"Price": @"500",
        @"Currency": @"THB"
    }];
}

- (IBAction)shareEvent:(id)sender
{
    [[ADAAnalytics sharedInstance] logEvent:@"Share" parameters:@{
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
