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

- (void)askForUserLocationPermission;
- (void)promptUserToGoToSettings;
    
@end

@implementation ADAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ADAAnalytics sharedInstance].delegate = self;
    self.locationManager = [[CLLocationManager alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self askForUserLocationPermission];
}

- (void)askForUserLocationPermission
{
    switch (CLLocationManager.authorizationStatus) {
        case kCLAuthorizationStatusNotDetermined:
            [self.locationManager requestWhenInUseAuthorization];
            break;
            
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted:
            [self promptUserToGoToSettings];
            break;
            
        default:
            break;
    }
}

- (void)promptUserToGoToSettings
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"We need to access your location" message:@"Please grant your location permission in the app Settings." preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *settings = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]
                                           options:@{}
                                 completionHandler:nil];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil];
    
    [alert addAction:settings];
    [alert addAction:cancel];
    [self presentViewController:alert animated:true completion:nil];
}

- (IBAction)onWelcomeTap:(id)sender
{
    [self askForUserLocationPermission];
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
