# ADAAnalytics iOS SDK

[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/AxiataADA/ADAAnalytics-iOS-SDK) [![Platform](https://img.shields.io/badge/platform-iOS-brightgreen.svg?style=flat)](https://github.com/AxiataADA/ADAAnalytics-iOS-SDK)

## Introduction
The ADAAnalytics iOS SDK is a cocoapods based library. Before proceeding further with the integration, you will need to obtain following items:
1. App name which is the unique name to identify your app (you can generate this yourself).
2. Base URL which is the URL of the SDK server API. (your server ip address)
3. App Key the key used to authenticate into SDK server (will be provided by us)
4. App Secret the secret key use to authenticate to the SDK server (will be provided by us)

## Minimum Requirements
-  iOS 10.0 and above
- Objective-C or Swift
- Cocoapods

## Installing Cocoapods
In Terminal, from your project root directory execute command:
```sh
$ sudo gem install cocoapods
```

## Setup SDK for project that does not have Cocoapods installed
1. In Terminal, from your project root directory execute command: 
```sh
$ pod init
```
2. From previous step, there should be a file name Podspec generated in your project folder open
 that file with any text editor and make these changes:
-- Uncomment the platform :ios line by deleting the ‘#’ sign at the beginning of the line and change the version number to 10.0
-- Under the Pods for `NAME_OF_YOUR_PROJECT` add
*pod 'ada-analytic-sdk', :git=> 'https://github.com/AxiataADA/ada-analytic-sdk.git'*

```ruby
platform :ios, '10.0'

target 'NAME_OF_YOUR_PROJECT' do
  use_frameworks!
  
# Pods for NAME_OF_YOUR_PROJECT
pod 'ada-analytic-sdk', :git=> 'https://github.com/AxiataADA/ada- analytic-sdk.git'

end
```
3. In Terminal, from your project root directory execute command: $ pod install
4. From previous step, there will be a xcode workspace file (*.xcworkspace) create for you in your project directory use that to open your project from now on.

## Setup SDK for project that already has Cocoapods installed
1. Add this pod into your Podfile
```ruby
 pod 'ada-analytic-sdk', :git=> 'https://github.com/AxiataADA/ada- analytic-sdk.git'
```
2. In Terminal, from your project root directory execute command: 
```sh
$ pod install
```

## SDK Initialization

Import SDK header to the AppDelegate file
#### Objective-C :
```obj-c
#import <ada_analytic_sdk/ADAAnalyticsStaticSDK.h>
```

#### Swift :
```swift
import ada_analytic_sdk
```

Initialize the SDK in the didFinishLaunchingWithOptions method with your ```APP_NAME```, ```BASE_URL```, ```APP_KEY``` and ```APP_SECRET``` given from us.

#### Objective-C :
```obj-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[ADAAnalytics sharedInstance] setupWithAppName:@"APP_NAME" baseUrl:@"BASE_URL" appKey:@"APP_KEY" appSecret:@"APP_SECRET"];
    return YES;
}
```

#### Swift :
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    ADAAnalytics.sharedInstance().setup(withAppName: "APP_NAME", baseUrl: "BASE_URL", appKey: "APP_KEY", appSecret: "APP_SECRET")
    return true
}
```

And add these 2 commands to applicationWillEnterForeground and applicationDidEnterBackground methods.

#### Objective-C :
```obj-c
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[ADAAnalytics sharedInstance] applicationWillEnterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[ADAAnalytics sharedInstance] applicationDidEnterBackground];
}
```

#### Swift :
```swift
func applicationWillEnterForeground(_ application: UIApplication) {
    ADAAnalytics.sharedInstance().applicationWillEnterForeground()
}

func applicationDidEnterBackground(_ application: UIApplication) {
    ADAAnalytics.sharedInstance().applicationDidEnterBackground()
}
```

## Usage

To log an event to server first import the sdk header to the file and simply call this method and pass the event name along with any additional data if any (optional).

#### Objective-C :
```obj-c
[[ADAAnalytics sharedInstance] logEvent:@"Event Name" parameters:@{ @"data-key-1": @"data-value-1", @"data-key-2": @"data-value-2" }];
```

#### Swift :
```swift
ADAAnalytics.sharedInstance().logEvent("Event Name", parameters: ["data-key-1": "data-value-1", "data-key-2": "data-value-2"])
```

## Author

ADA Asia (https://ada-asia.com)

## License

ADAAnalytics is available under the MIT license.