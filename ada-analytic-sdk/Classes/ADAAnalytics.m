//
//  ADAAnalytics.m
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 25/5/2561 BE.
//

@import AdSupport;
@import CoreLocation;
@import CoreTelephony;
@import CoreBluetooth;

#import "ADAAnalytics.h"
#import "URLRequestSigner.h"
#import "DeviceUID.h"
#import <AFNetworking/AFNetworking.h>
#import <Reachability/Reachability.h>
#import "StringHash.h"
#import <sys/utsname.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>

#define SDK_ACTION_KEY @"ADA_SDK_ACTION"
#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

@interface ADAAnalytics(private) <CLLocationManagerDelegate, CBCentralManagerDelegate>

- (void)configure;
- (void)initRecorder;
- (void)prepareLocationManager;
- (void)prepareBluetoothManager;
- (void)scanForBluetoothDevices;
- (BOOL)hasBluetoothPermission;
- (NSString *)identifierForAdvertising;
- (NSDate *)appInstalledDate;
- (NSString*)deviceName;
- (NSString *)internetConnectionType;
- (NSString *)getCarrierName;
- (NSString *)getCountryCode;
- (NSMutableDictionary *)getDefaultEventParameterForEvent:(NSString *)eventName;
- (NSString *)getIPAddress:(BOOL)preferIPv4;
- (NSDictionary *)getIPAddresses;

@end

@implementation ADAAnalytics

CLLocationManager *locationManager;
CBCentralManager *centralManager;
NSString* maid;
NSString* uniqueId;
NSDate* installedDate;
CLLocation* lastLocation;
NSString* appName;
NSString *apiUrl;
NSString *appKey;
NSString *appSecret;
NSString* iOSVersion;
NSString* phoneModel;
NSString* carrier;
NSString* currentSessionID;
NSString* requestToken;
BOOL isLoggedIn;
BOOL isAuthorized;
NSDictionary *extraHeaders;
NSMutableArray *pendingLogs;
BOOL bluetoothOn;
NSMutableArray *recentPeripherals;
NSMutableArray *recentPeripheralIds;
NSTimer *timer;

+ (instancetype)sharedInstance
{
    static ADAAnalytics *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ADAAnalytics alloc] init];
    });
    return sharedInstance;
}

#pragma Private Methods Implementation

- (void)configure
{
    maid = [self identifierForAdvertising];
    uniqueId = [DeviceUID uid];
    installedDate = [self appInstalledDate];
    iOSVersion = [[UIDevice currentDevice] systemVersion];
    phoneModel = [self deviceName];
    carrier = [self getCarrierName];
    currentSessionID = [[NSUUID UUID] UUIDString];
    pendingLogs = [[NSMutableArray alloc] init];
    recentPeripherals = [[NSMutableArray alloc] init];
    recentPeripheralIds = [[NSMutableArray alloc] init];
    isLoggedIn = NO;
    isAuthorized = YES;
    bluetoothOn = NO;
    [self prepareLocationManager];
    [self prepareBluetoothManager];
}

- (void)prepareLocationManager
{
    if (!([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways ||
          [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse))
    {
        return;
    }
    
    if (locationManager == nil) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        lastLocation = locationManager.location;
    }
    [locationManager startMonitoringSignificantLocationChanges];
}

- (BOOL)hasBluetoothPermission
{
    if (@available(iOS 13.1, *)) {
        return (CBCentralManager.authorization == CBManagerAuthorizationAllowedAlways);
    } else {
        return (CBPeripheralManager.authorizationStatus == CBPeripheralManagerAuthorizationStatusAuthorized);
    }
}

- (void)prepareBluetoothManager
{
//    if (@available(iOS 13.1, *)) {
//        if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSBluetoothAlwaysUsageDescription"]) {
//            return;
//        }
//    } else {
//        if (![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSBluetoothPeripheralUsageDescription"]) {
//            return;
//        }
//    }
//
//    if (centralManager == nil) {
//        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
//    }
//    [self scanForBluetoothDevices];
}

- (NSString *)identifierForAdvertising
{
    // Check whether advertising tracking is enabled
    if ([[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]) {
        NSUUID *identifier = [[ASIdentifierManager sharedManager] advertisingIdentifier];
        return [identifier UUIDString];
    }
    
    // Get and return IDFA
    return nil;
}

- (NSDate *)appInstalledDate
{
    NSURL* urlToDocumentsFolder = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    __autoreleasing NSError *error;
    NSDate *installDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:urlToDocumentsFolder.path error:&error] objectForKey:NSFileCreationDate];
    return installDate;
}

- (NSString*)deviceName
{
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
    
    static NSDictionary* deviceNamesByCode = nil;
    
    if (!deviceNamesByCode) {
        
        deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch",        // (6th Generation)
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPad1,1"   : @"iPad",              // (Original)
                              @"iPad2,1"   : @"iPad 2",            //
                              @"iPad3,1"   : @"iPad",              // (3rd Generation)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   : @"iPad",              // (4th Generation)
                              @"iPad2,5"   : @"iPad Mini",         // (Original)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                              
                              @"iPhone11,2" : @"iPhone XS",
                              @"iPhone11,4" : @"iPhone XS Max",
                              @"iPhone11,6" : @"iPhone XS Max Global",
                              @"iPhone11,8" : @"iPhone XR",
                              @"iPhone12,1" : @"iPhone 11",
                              @"iPhone12,3" : @"iPhone 11 Pro",
                              @"iPhone12,5" : @"iPhone 11 Pro Max",
                              
                              @"iPad4,1"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   : @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   : @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   : @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584)
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652)
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    }
    
    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    
    if (!deviceName) {
        // Not found on database. At least guess main device type from string contents:
        
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = [NSString stringWithFormat: @"iPod Touch (%@)", code];
        }
        else if([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = [NSString stringWithFormat: @"iPad (%@)", code];
        }
        else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = [NSString stringWithFormat: @"iPhone (%@)", code];
        }
        else {
            deviceName = [NSString stringWithFormat: @"Unknown (%@)", code];
        }
    }
    
    return deviceName;
}

- (NSString *)internetConnectionType
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
    NetworkStatus status = [reachability currentReachabilityStatus];
    
    if (status == NotReachable) {
        return @"No connection";
    } else if (status == ReachableViaWiFi) {
        return @"Wifi";
    } else if (status == ReachableViaWWAN) {
        return @"Cellular Data";
    }
    return @"Unknown";
}

- (NSString *)getCarrierName
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return [carrier carrierName];
}

- (NSString *)getCountryCode
{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    NSString *carrierCountryCode = [carrier isoCountryCode];
    if (carrierCountryCode && ![carrierCountryCode isEqualToString:@""]) {
        return carrierCountryCode;
    } else {
        NSLocale *currentLocale = [NSLocale currentLocale];
        NSString *countryCode = [currentLocale objectForKey: NSLocaleCountryCode];
        return countryCode;
    }
}

- (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6,*/ IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
                            @[ /*IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4,*/ IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;

    NSDictionary *addresses = [self getIPAddresses];

    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
        {
            address = addresses[key];
            if(address) *stop = YES;
        } ];
    return address ? address : @"0.0.0.0";
}

- (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}

- (NSMutableDictionary *)getDefaultEventParameterForEvent:(NSString *)eventName
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    [formatter setCalendar: [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
    NSString *installedDateString = [formatter stringFromDate:installedDate];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    [parameters setValue:installedDateString forKey:@"installed_date"];
    [parameters setValue:timestamp forKey:@"timestamp"];
    [parameters setValue:currentSessionID forKey:@"session_id"];
    [parameters setValue:eventName forKey:@"event_id"];
    
    NSMutableDictionary *deviceDict = [[NSMutableDictionary alloc] init];
    [deviceDict setValue:@"Apple" forKey:@"make"];
    [deviceDict setValue:phoneModel forKey:@"model"];
    [deviceDict setValue:@"iOS" forKey:@"os"];
    [deviceDict setValue:iOSVersion forKey:@"osv"];
    [deviceDict setValue:maid forKey:@"ifa"];
    [deviceDict setValue:[self getIPAddress: YES] forKey:@"ip"];
    [deviceDict setValue:uniqueId forKey:@"id"];
    [deviceDict setValue:@"1.1.0" forKey:@"sdkv"];
    [parameters setValue:deviceDict forKey:@"device"];
    
    NSMutableDictionary *appDict = [[NSMutableDictionary alloc] init];
    [appDict setValue:appName forKey:@"name"];
    [appDict setValue:[[NSBundle mainBundle] bundleIdentifier] forKey:@"bundle"];
    [parameters setValue:appDict forKey:@"app"];
    
    NSMutableDictionary *telephonyDict = [[NSMutableDictionary alloc] init];
    [telephonyDict setValue:[self getCountryCode] forKey:@"countryCode"];
    [telephonyDict setValue:carrier forKey:@"carrierName"];
    NSString *connectionType = [self internetConnectionType];
    if (connectionType) {
        [telephonyDict setValue:@{@"@type": @"NetworkType", @"name": connectionType} forKey:@"networkType"];
    }
    [parameters setValue:telephonyDict forKey:@"telephony"];
    
    if (lastLocation) {
        NSString *latitude = [NSString stringWithFormat:@"%f", lastLocation.coordinate.latitude];
        NSString *longitude = [NSString stringWithFormat:@"%f", lastLocation.coordinate.longitude];
        NSDictionary *locationDict = @{@"geo": @{@"lat": latitude, @"lon": longitude}};
        [parameters setValue:locationDict forKey:@"geo"];
    }
    
//    if ([recentPeripherals count] > 0) {
//        [parameters setValue:recentPeripherals forKey:@"bluetooth_devices"];
//    }
    
    return parameters;
}

#pragma CoreLocation Delegates

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    lastLocation = [locations lastObject];
}

#pragma CoreBluetooth Delegates

- (void)scanForBluetoothDevices
{
//    if (centralManager && [self hasBluetoothPermission] && bluetoothOn) {
//        [centralManager scanForPeripheralsWithServices:nil options:nil];
//
//        double delayInSeconds = 4.0;
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            [centralManager stopScan];
//        });
//    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
//    if ([central state] == CBManagerStatePoweredOn) {
//        bluetoothOn = YES;
//        [self scanForBluetoothDevices];
//    } else {
//        if (centralManager && [self hasBluetoothPermission] && bluetoothOn) {
//            [centralManager stopScan];
//        }
//        bluetoothOn = NO;
//        [recentPeripherals removeAllObjects];
//        [recentPeripheralIds removeAllObjects];
//    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    
//    if ([RSSI integerValue] > -15) {
//        return;
//    }
//
//    if ([RSSI integerValue] < -90) {
//        return;
//    }
//
//    NSString *id = [[peripheral identifier] UUIDString];
//    if ([recentPeripheralIds containsObject:id]) {
//        return;
//    } else {
//        [recentPeripheralIds addObject:id];
//    }
//
//    NSMutableDictionary *peripheralData = [[NSMutableDictionary alloc] init];
//
//    if (id != nil) {
//        [peripheralData setObject:id forKey:@"id"];
//        [peripheralData setObject:@"UNKNOWN" forKey:@"type"];
//        [peripheralData setObject:RSSI forKey:@"rssi"];
//
//        if ([peripheral name] != nil) {
//            [peripheralData setObject:[peripheral name] forKey:@"name"];
//        }
//    }
//
//    [recentPeripherals addObject:peripheralData];
}

#pragma Public Methods Implementation

- (void)setupWithAppName:(NSString *)mAppName baseUrl:(NSString *)baseUrl appKey:(NSString *)mAppKey appSecret:(NSString *)mAppSecret
{
    appName = mAppName;
    apiUrl = baseUrl;
    appKey = mAppKey;
    appSecret = mAppSecret;
    [self configure];
    [self doApiLogin];
    [self timerTrigger];
}
    
- (void)doApiLogin {
    NSDictionary *params = @{@"appKey": appKey, @"appSecret": appSecret};
    NSError *writeError = nil;
    
    NSData* bodyData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&writeError];
    NSString* jsonString = [[NSString alloc]initWithData:bodyData encoding:NSUTF8StringEncoding];
    
    NSString* url = [NSString stringWithFormat:@"%@/login", apiUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:120];
    
    [request setHTTPMethod:@"POST"];
    [request setValue: @"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setValue: @"application/json; encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue: @"application/json; encoding=utf-8" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody: [jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    AFJSONRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
    [serializer setStringEncoding:NSUTF8StringEncoding];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        long statusCode = (long)[httpResponse statusCode];
        NSLog(@"Response Status Code: %ld", statusCode);
        
        if (!error) {
            // set token
            if ([responseObject isKindOfClass:[NSData class]]) {
                NSData *responseData = responseObject;
                NSError* error;
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                                                                     options:kNilOptions
                                                                       error:&error];
                requestToken = [json objectForKey:@"token"];
                isLoggedIn = YES;
                for (NSDictionary* log in pendingLogs) {
                    [self doSendLogWithParams:log];
                }
                [pendingLogs removeAllObjects];
            }
        } else {
            if (statusCode == 403 || statusCode == 401) {
                isAuthorized = NO;
                NSLog(@"ADAAnalytics Failed: Unauthorized!");
            } else {
                NSLog(@"ADAAnalytics Failed: Invalid App Credential");
            }
        }
    }] resume];
}

- (void)setExtraRequestHeader:(NSDictionary *)headers
{
    extraHeaders = headers;
}

- (void)applicationDidEnterBackground
{
    if (timer) {
        [timer invalidate];
    }
    [self timerTrigger];
    
    if (centralManager && bluetoothOn) {
        [centralManager stopScan];
    }
}

- (void)applicationWillEnterForeground
{
    currentSessionID = [[NSUUID UUID] UUIDString];
    isAuthorized = YES;
    
    if (timer) {
        [timer invalidate];
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 600
                                             target: self
                                           selector: @selector(timerTrigger)
                                           userInfo: nil
                                            repeats: YES];
    
    [self scanForBluetoothDevices];
}

- (void)timerTrigger
{
    [self logEvent:SDK_ACTION_KEY];
}

- (void)logEvent:(NSString *)eventName
{
    [self logEvent:eventName parameters:@{}];
}

- (void)logEvent:(NSString *)eventName parameters:(NSDictionary *)parameters
{
    [self prepareLocationManager];
    [self prepareBluetoothManager];
    
    NSMutableDictionary *defaultParams = [self getDefaultEventParameterForEvent:eventName];
    NSMutableDictionary *inAppTag = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    [inAppTag setValue:eventName forKey:@"action"];
    for (NSString* param in parameters.allKeys) {
        [inAppTag setValue:parameters[param] forKey:param];
    }
    [defaultParams setValue:inAppTag forKey:@"inAppTag"];
    
    if (!isLoggedIn) {
        if (isAuthorized) {
            [pendingLogs addObject:defaultParams];
        }
        return;
    } else if (!isAuthorized) {
        return;
    }
    
    [self doSendLogWithParams:defaultParams];
}
    
- (void)doSendLogWithParams:(NSDictionary *)params {
    NSError *writeError = nil;
    
    NSData* bodyData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&writeError];
    NSString* jsonString = [[NSString alloc]initWithData:bodyData encoding:NSUTF8StringEncoding];
    
    NSString* url = [NSString stringWithFormat:@"%@/ada-logs", apiUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData  timeoutInterval:120];
    
    [request setHTTPMethod:@"POST"];
    [request setValue: @"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setValue: @"application/json; encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue: @"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue: requestToken forHTTPHeaderField:@"Authorization"];
    
    if (extraHeaders != nil && extraHeaders.count > 0) {
        for (NSString* key in extraHeaders.allKeys) {
            [request setValue:extraHeaders[key] forHTTPHeaderField:key];
        }
    }
    
    [request setHTTPBody: [jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
#ifdef DEBUG
    NSLog(@"%@", jsonString);
#endif
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        long statusCode = (long)[httpResponse statusCode];
        NSLog(@"Response Status Code: %ld", statusCode);
        
        if (!error) {
            [self.delegate didSuccessLogEventToServer];
        } else {
            if (statusCode == 403 || statusCode == 401) {
                isAuthorized = NO;
                NSLog(@"ADAAnalytics Failed: Unauthorized!");
            } else {
                NSLog(@"Failed Reason: %@", error.localizedDescription);
                [self.delegate didFailLogEventToServer:error];
            }
        }
    }] resume];
}

@end
