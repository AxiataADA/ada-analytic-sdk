//
//  ADAAnalytics.h
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 25/5/2561 BE.
//

#import <Foundation/Foundation.h>

@protocol ADAAnalyticsDelegate

- (void)didSuccessLogEventToServer;
- (void)didFailLogEventToServer:(NSError *)error;

@end

@interface ADAAnalytics : NSObject

+ (instancetype)sharedInstance;

@property(nonatomic, assign) id<ADAAnalyticsDelegate> delegate;

- (void)setupWithAppName:(NSString *)mAppName baseUrl:(NSString *)baseUrl appKey:(NSString *)mAppKey appSecret:(NSString *)mAppSecret;
- (void)setExtraRequestHeader:(NSDictionary *)headers;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)logEvent:(NSString *)eventName;
- (void)logEvent:(NSString *)eventName parameters:(NSDictionary *)parameters;

@end
