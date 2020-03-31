//
//  AWSCategory.h
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 18/6/2561 BE.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const AWSDateRFC822DateFormat1;
FOUNDATION_EXPORT NSString *const AWSDateISO8601DateFormat1;
FOUNDATION_EXPORT NSString *const AWSDateISO8601DateFormat2;
FOUNDATION_EXPORT NSString *const AWSDateISO8601DateFormat3;
FOUNDATION_EXPORT NSString *const AWSDateShortDateFormat1;
FOUNDATION_EXPORT NSString *const AWSDateShortDateFormat2;
FOUNDATION_EXPORT NSString *const AWSDateAWZFormat;

@interface NSDate (AWS)

+ (NSDate *)aws_clockSkewFixedDate;

+ (NSDate *)aws_dateFromString:(NSString *)string;
+ (NSDate *)aws_dateFromString:(NSString *)string format:(NSString *)dateFormat;
- (NSString *)aws_stringValue:(NSString *)dateFormat;

/**
 * Set the clock skew for the current device.  This clock skew will be used for calculating
 * signatures to AWS signatures and for parsing/converting date values from responses.
 *
 * @param clockskew the skew (in seconds) for this device.  If the clock on the device is fast, pass positive skew to correct.  If the clock on the device is slow, pass negative skew to correct.
 */
+ (void)aws_setRuntimeClockSkew:(NSTimeInterval)clockskew;

/**
 * Get the clock skew for the current device.
 *
 * @return the skew (in seconds) currently set for this device.  Positive clock skew implies the device is fast, negative implies the device is slow.
 */
+ (NSTimeInterval)aws_getRuntimeClockSkew;

@end

@interface NSString (AWS)

+ (NSString *)aws_base64md5FromData:(NSData *)data;
- (BOOL)aws_isBase64Data;
- (NSString *)aws_stringWithURLEncoding;
- (NSString *)aws_stringWithURLEncodingPath;
- (NSString *)aws_stringWithURLEncodingPathWithoutPriorDecoding;
- (NSString *)aws_md5String;
- (NSString *)aws_md5StringLittleEndian;
- (BOOL)aws_isVirtualHostedStyleCompliant;

@end
