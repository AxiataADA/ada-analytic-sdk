//
//  ADAAppDelegate.m
//  ada-analytic-sdk
//
//  Created by chavalit.v@ada-asia.com on 03/31/2020.
//  Copyright (c) 2020 chavalit.v@ada-asia.com. All rights reserved.
//

#import "ADAAppDelegate.h"
#import <ADAAnalytics.h>

#define APP_NAME @"YOUR_APP_NAME_HERE"
#define BASE_URL @"127.0.0.1"
#define APP_KEY @"YOUR_APP_KEY_HERE"
#define APP_SECRET @"YOUR_APP_SECRET_HERE"

@implementation ADAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[ADAAnalytics sharedInstance] setupWithAppName:APP_NAME
                                            baseUrl:BASE_URL
                                             appKey:APP_KEY
                                          appSecret:APP_SECRET];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[ADAAnalytics sharedInstance] applicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[ADAAnalytics sharedInstance] applicationWillEnterForeground];
}

@end
