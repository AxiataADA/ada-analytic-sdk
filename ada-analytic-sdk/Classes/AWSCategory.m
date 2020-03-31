//
//  AWSCategory.m
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 18/6/2561 BE.
//

#import "AWSCategory.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

NSString *const AWSDateRFC822DateFormat1 = @"EEE, dd MMM yyyy HH:mm:ss z";
NSString *const AWSDateISO8601DateFormat1 = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
NSString *const AWSDateISO8601DateFormat2 = @"yyyyMMdd'T'HHmmss'Z'";
NSString *const AWSDateISO8601DateFormat3 = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
NSString *const AWSDateShortDateFormat1 = @"yyyyMMdd";
NSString *const AWSDateShortDateFormat2 = @"yyyy-MM-dd";
NSString *const AWSDateAWZFormat = @"yyyyMMdd'T'HHmmssXXXXX";

@implementation NSString (AWS)

+ (NSString *)aws_base64md5FromData:(NSData *)data {
    
    if([data length] > UINT32_MAX)
    {
        //The NSData size is too large. The maximum allowable size is UINT32_MAX.
        return nil;
    }
    
    const void    *cStr = [data bytes];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(cStr, (uint32_t)[data length], result);
    
    NSData *md5 = [[NSData alloc] initWithBytes:result length:CC_MD5_DIGEST_LENGTH];
    return [md5 base64EncodedStringWithOptions:kNilOptions];
}

- (BOOL)aws_isBase64Data {
    if ([self length] % 4 == 0) {
        static NSCharacterSet *invertedBase64CharacterSet = nil;
        if (invertedBase64CharacterSet == nil) {
            invertedBase64CharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="] invertedSet];
        }
        return [self rangeOfCharacterFromSet:invertedBase64CharacterSet
                                     options:NSLiteralSearch].location == NSNotFound;
    }
    return NO;
}

- (NSString *)aws_stringWithURLEncoding {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (__bridge CFStringRef)[self aws_decodeURLEncoding],
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\();:@&=+$,/?%#[] ",
                                                                                 kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSString *)aws_stringWithURLEncodingPath {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (__bridge CFStringRef)[self aws_decodeURLEncoding],
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\();:@&=+$,?%#[] ",
                                                                                 kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSString *)aws_stringWithURLEncodingPathWithoutPriorDecoding {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\();:@&=+$,?%#[] ",
                                                                                 kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSString *)aws_decodeURLEncoding {
    NSString *result = [self stringByRemovingPercentEncoding];
    return result?result:self;
}

- (NSString *)aws_md5String {
    NSData *dataString = [self dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digestArray[CC_MD5_DIGEST_LENGTH];
    CC_MD5([dataString bytes], (CC_LONG)[dataString length], digestArray);
    
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", digestArray[i]];
    }
    return md5String;
}

- (NSString *)aws_md5StringLittleEndian {
    NSData *dataString = [self dataUsingEncoding:NSUTF16LittleEndianStringEncoding];
    unsigned char digestArray[CC_MD5_DIGEST_LENGTH];
    CC_MD5([dataString bytes], (CC_LONG)[dataString length], digestArray);
    
    NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", digestArray[i]];
    }
    return md5String;
}

- (BOOL)aws_isDNSBucketName {
    if ([self length] < 3 || [self length] > 63) {
        return NO;
    }
    
    if ([self hasSuffix:@"-"]) {
        return NO;
    }
    
    if ([self aws_contains:@"_"]) {
        return NO;
    }
    
    if ([self aws_contains:@"-."] || [self aws_contains:@".-"]) {
        return NO;
    }
    
    if ([[self lowercaseString] isEqualToString:self] == NO) {
        return NO;
    }
    
    return YES;
}

- (BOOL)aws_isVirtualHostedStyleCompliant {
    if (![self aws_isDNSBucketName]) {
        return NO;
    } else {
        return ![self aws_contains:@"."];
    }
}

- (BOOL)aws_contains:(NSString *)searchString {
    NSRange range = [self rangeOfString:searchString];
    
    return (range.location != NSNotFound);
}

@end

@implementation NSDate (AWS)

static NSTimeInterval _clockskew = 0.0;

+ (NSDate *)aws_clockSkewFixedDate {
    return [[NSDate date] dateByAddingTimeInterval:-1 * _clockskew];
}

+ (NSDate *)aws_dateFromString:(NSString *)string {
    NSDate *parsedDate = nil;
    NSArray *arrayOfDateFormat = @[AWSDateRFC822DateFormat1,
                                   AWSDateISO8601DateFormat1,
                                   AWSDateISO8601DateFormat2,
                                   AWSDateISO8601DateFormat3];
    
    for (NSString *dateFormat in arrayOfDateFormat) {
        if (!parsedDate) {
            parsedDate = [NSDate aws_dateFromString:string format:dateFormat];
        } else {
            break;
        }
    }
    
    return parsedDate;
}

+ (NSDate *)aws_dateFromString:(NSString *)string format:(NSString *)dateFormat {
    if ([dateFormat isEqualToString:AWSDateRFC822DateFormat1]) {
        return [[NSDate aws_RFC822Date1Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat1]) {
        return [[NSDate aws_ISO8601Date1Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat2]) {
        return [[NSDate aws_ISO8601Date2Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat3]) {
        return [[NSDate aws_ISO8601Date3Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateShortDateFormat1]) {
        return [[NSDate aws_ShortDateFormat1Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateShortDateFormat2]) {
        return [[NSDate aws_ShortDateFormat2Formatter] dateFromString:string];
    }
    if ([dateFormat isEqualToString:AWSDateAWZFormat]) {
        return [[NSDate aws_AWZDateFormatter] dateFromString:string];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = dateFormat;
    
    return [dateFormatter dateFromString:string];
}

- (NSString *)aws_stringValue:(NSString *)dateFormat {
    if ([dateFormat isEqualToString:AWSDateRFC822DateFormat1]) {
        return [[NSDate aws_RFC822Date1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat1]) {
        return [[NSDate aws_ISO8601Date1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat2]) {
        return [[NSDate aws_ISO8601Date2Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateISO8601DateFormat3]) {
        return [[NSDate aws_ISO8601Date3Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateShortDateFormat1]) {
        return [[NSDate aws_ShortDateFormat1Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateShortDateFormat2]) {
        return [[NSDate aws_ShortDateFormat2Formatter] stringFromDate:self];
    }
    if ([dateFormat isEqualToString:AWSDateAWZFormat]) {
        return [[NSDate aws_AWZDateFormatter] stringFromDate:self];
    }
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = dateFormat;
    
    return [dateFormatter stringFromDate:self];
}

+ (NSDateFormatter *)aws_RFC822Date1Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateRFC822DateFormat1;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_ISO8601Date1Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateISO8601DateFormat1;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_ISO8601Date2Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateISO8601DateFormat2;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_ISO8601Date3Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateISO8601DateFormat3;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_ShortDateFormat1Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateShortDateFormat1;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_ShortDateFormat2Formatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateShortDateFormat2;
    });
    
    return _dateFormatter;
}

+ (NSDateFormatter *)aws_AWZDateFormatter {
    static NSDateFormatter *_dateFormatter = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = AWSDateAWZFormat;
    });
    
    return _dateFormatter;
}

+ (void)aws_setRuntimeClockSkew:(NSTimeInterval)clockskew {
    @synchronized(self) {
        _clockskew = clockskew;
    }
}

+ (NSTimeInterval)aws_getRuntimeClockSkew {
    @synchronized(self) {
        return _clockskew;
    }
}

@end
