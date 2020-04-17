#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "ADAAnalytics.h"
#import "ADAAnalyticsStaticSDK.h"
#import "AWSCategory.h"
#import "DeviceUID.h"
#import "StringHash.h"
#import "URLRequestSigner.h"

FOUNDATION_EXPORT double ada_analytic_sdkVersionNumber;
FOUNDATION_EXPORT const unsigned char ada_analytic_sdkVersionString[];

