//
//  URLRequestSigner.m
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 18/6/2561 BE.
//

#import "URLRequestSigner.h"
#import "AWSCategory.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>

#define CC_SHA256_DIGEST_LENGTH    32
static NSString *const AWSSigV4Marker = @"AWS4";
NSString *const AWSSignatureV4Algorithm = @"AWS4-HMAC-SHA256";
NSString *const AWSSignatureV4Terminator = @"aws4_request";
NSString *const AWSSignatureV4Region = @"us-east-1";
NSString *const AWSSignatureV4ServiceType = @"execute-api";

@implementation URLRequestSigner

- (NSString *)getCanonicalizedRequest:(NSString *)method path:(NSString *)path query:(NSString *)query headers:(NSDictionary *)headers contentSha256:(NSString *)contentSha256 {
    NSMutableString *canonicalRequest = [NSMutableString new];
    [canonicalRequest appendString:method];
    [canonicalRequest appendString:@"\n"];
    [canonicalRequest appendString:path]; // Canonicalized resource path
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getCanonicalizedQueryString:query]]; // Canonicalized Query String
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getCanonicalizedHeaderString:headers]];
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[self getSignedHeadersString:headers]];
    [canonicalRequest appendString:@"\n"];
    
    [canonicalRequest appendString:[NSString stringWithFormat:@"%@", contentSha256]];
    
    return canonicalRequest;
}

- (NSString *)getCanonicalizedQueryString:(NSString *)query {
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *queryDictionary = [NSMutableDictionary new];
    [[query componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *components = [obj componentsSeparatedByString:@"="];
        if ([components count] == 2) {
            // ?a=b
            NSString *key = components[0]; // a
            NSString *value = components[1]; // b
            if (queryDictionary[key]) {
                // If the query parameter has multiple values, add it in the mutable array
                [[queryDictionary objectForKey:key] addObject:value];
            } else {
                // Insert the value for query parameter as an element in mutable array
                [queryDictionary setObject:[@[value] mutableCopy] forKey:key];
            }
        }
    }];
    
    NSMutableArray *sortedQuery = [[NSMutableArray alloc] initWithArray:[queryDictionary allKeys]];
    
    [sortedQuery sortUsingSelector:@selector(compare:)];
    
    NSMutableString *sortedQueryString = [NSMutableString new];
    for (NSString *key in sortedQuery) {
        [queryDictionary[key] sortUsingSelector:@selector(compare:)];
        for (NSString *parameterValue in queryDictionary[key]) {
            [sortedQueryString appendString:key];
            [sortedQueryString appendString:@"="];
            [sortedQueryString appendString:parameterValue];
            [sortedQueryString appendString:@"&"];
        }
    }
    // Remove the trailing & for a valid canonical query string.
    if ([sortedQueryString hasSuffix:@"&"]) {
        return [sortedQueryString substringToIndex:[sortedQueryString length] - 1];
    }
    
    return sortedQueryString;
}

- (NSString *)getCanonicalizedHeaderString:(NSDictionary *)headers {
    NSMutableArray *sortedHeaders = [[NSMutableArray alloc] initWithArray:[headers allKeys]];
    
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableString *headerString = [NSMutableString new];
    for (NSString *header in sortedHeaders) {
        [headerString appendString:[header lowercaseString]];
        [headerString appendString:@":"];
        [headerString appendString:[headers valueForKey:header]];
        [headerString appendString:@"\n"];
    }
    
    // SigV4 expects all whitespace in headers and values to be collapsed to a single space
    NSCharacterSet *whitespaceChars = [NSCharacterSet whitespaceCharacterSet];
    NSPredicate *noEmptyStrings = [NSPredicate predicateWithFormat:@"SELF != ''"];
    
    NSArray *parts = [headerString componentsSeparatedByCharactersInSet:whitespaceChars];
    NSArray *nonWhitespace = [parts filteredArrayUsingPredicate:noEmptyStrings];
    return [nonWhitespace componentsJoinedByString:@" "];
}

- (NSString *)getSignedHeadersString:(NSDictionary *)headers {
    NSMutableArray *sortedHeaders = [[NSMutableArray alloc] initWithArray:[headers allKeys]];
    
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableString *headerString = [NSMutableString new];
    for (NSString *header in sortedHeaders) {
        if ([headerString length] > 0) {
            [headerString appendString:@";"];
        }
        [headerString appendString:[header lowercaseString]];
    }
    
    return headerString;
}

- (NSString *)hexEncode:(NSString *)string {
    NSUInteger len = [string length];
    if (len == 0) {
        return @"";
    }
    unichar *chars = malloc(len * sizeof(unichar));
    if (chars == NULL) {
        // this situation is irrecoverable and we don't want to return something corrupted, so we raise an exception (avoiding NSAssert that may be disabled)
        [NSException raise:@"NSInternalInconsistencyException" format:@"failed malloc" arguments:nil];
        return nil;
    }
    
    [string getCharacters:chars];
    
    NSMutableString *hexString = [NSMutableString new];
    for (NSUInteger i = 0; i < len; i++) {
        if ((int)chars[i] < 16) {
            [hexString appendString:@"0"];
        }
        [hexString appendString:[NSString stringWithFormat:@"%x", chars[i]]];
    }
    free(chars);
    
    return hexString;
}

- (NSData *)sha256HMacWithData:(NSData *)data withKey:(NSData *)key {
    CCHmacContext context;
    
    CCHmacInit(&context, kCCHmacAlgSHA256, [key bytes], [key length]);
    CCHmacUpdate(&context, [data bytes], [data length]);
    
    unsigned char digestRaw[CC_SHA256_DIGEST_LENGTH];
    NSInteger digestLength = CC_SHA256_DIGEST_LENGTH;
    
    CCHmacFinal(&context, digestRaw);
    
    return [NSData dataWithBytes:digestRaw length:digestLength];
}

- (NSData *)getV4DerivedKey:(NSString *)secret date:(NSString *)dateStamp region:(NSString *)regionName service:(NSString *)serviceName {
    // AWS4 uses a series of derived keys, formed by hashing different pieces of data
    NSString *kSecret = [NSString stringWithFormat:@"%@%@", AWSSigV4Marker, secret];
    NSData *kDate = [self sha256HMacWithData:[dateStamp dataUsingEncoding:NSUTF8StringEncoding]
                                     withKey:[kSecret dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *kRegion = [self sha256HMacWithData:[regionName dataUsingEncoding:NSASCIIStringEncoding]
                                       withKey:kDate];
    NSData *kService = [self sha256HMacWithData:[serviceName dataUsingEncoding:NSUTF8StringEncoding]
                                        withKey:kRegion];
    NSData *kSigning = [self sha256HMacWithData:[AWSSignatureV4Terminator dataUsingEncoding:NSUTF8StringEncoding]
                                        withKey:kService];
    
    return kSigning;
}

- (NSData *)hash:(NSData *)dataToHash {
    if ([dataToHash length] > UINT32_MAX) {
        return nil;
    }
    
    const void *cStr = [dataToHash bytes];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(cStr, (uint32_t)[dataToHash length], result);
    
    return [[NSData alloc] initWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

- (NSString *)hashString:(NSString *)stringToHash {
    return [[NSString alloc] initWithData:[self hash:[stringToHash dataUsingEncoding:NSUTF8StringEncoding]]
                                 encoding:NSASCIIStringEncoding];
}

- (void)signRequest:(NSMutableURLRequest *)request secretSigningKey:(NSString *)secretSigningKey accessKeyId:(NSString *)accessKeyId apiKey:(NSString *)apiKey {
    
    NSDate *date = [NSDate aws_clockSkewFixedDate];
    NSString *dateTime = [date aws_stringValue:AWSDateAWZFormat];
    [request addValue:dateTime forHTTPHeaderField:@"X-Amz-Date"];
    [request addValue:apiKey forHTTPHeaderField:@"X-API-Key"];
    [request addValue:request.URL.host forHTTPHeaderField:@"Host"];
    
    NSString *absoluteString = [request.URL absoluteString];
    if ([absoluteString hasSuffix:@"/"]) {
        request.URL = [NSURL URLWithString:[absoluteString substringToIndex:[absoluteString length] - 1]];
    }
    
    NSDate *xAmzDate = [NSDate aws_dateFromString:[request valueForHTTPHeaderField:@"X-Amz-Date"]
                                           format:AWSDateISO8601DateFormat2];
    
    NSString *dateStamp = [xAmzDate aws_stringValue:AWSDateShortDateFormat1];
    
    NSString *cfPath = (NSString *)CFBridgingRelease(CFURLCopyPath((CFURLRef)request.URL));
    //For  AWS Services (except S3) , url-encoded URL will be used to generate CanonicalURL directly. (i.e. the encoded URL will be encoded again, e.g. "%3A" -> "%253A"
    NSString *path = [cfPath aws_stringWithURLEncodingPathWithoutPriorDecoding];
    if (path.length == 0) {
        path = [NSString stringWithFormat:@"/"];
    }
    NSString *query = request.URL.query;
    if (query == nil) {
        query = [NSString stringWithFormat:@""];
    }
    
    NSString *contentSha256 = [self hexEncode:[[NSString alloc] initWithData:[self hash:request.HTTPBody] encoding:NSASCIIStringEncoding]];
    
    NSString *canonicalRequest = [self getCanonicalizedRequest:request.HTTPMethod
                                                          path:path
                                                         query:query
                                                       headers:request.allHTTPHeaderFields
                                                 contentSha256:contentSha256];
    
    NSString *scope = [NSString stringWithFormat:@"%@/%@/%@/%@",
                       dateStamp,
                       AWSSignatureV4Region,
                       AWSSignatureV4ServiceType,
                       AWSSignatureV4Terminator];
    NSString *signingCredentials = [NSString stringWithFormat:@"%@/%@",
                                    accessKeyId,
                                    scope];
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@",
                              AWSSignatureV4Algorithm,
                              [request valueForHTTPHeaderField:@"X-Amz-Date"],
                              scope,
                              [self hexEncode:[self hashString:canonicalRequest]]];
    
    NSData *kSigning  = [self getV4DerivedKey:secretSigningKey
                                         date:dateStamp
                                       region:AWSSignatureV4Region
                                      service:AWSSignatureV4ServiceType];
    NSData *signature = [self sha256HMacWithData:[stringToSign dataUsingEncoding:NSUTF8StringEncoding]
                                         withKey:kSigning];
    
    NSString *credentialsAuthorizationHeader = [NSString stringWithFormat:@"Credential=%@", signingCredentials];
    NSString *signedHeadersAuthorizationHeader = [NSString stringWithFormat:@"SignedHeaders=%@", [self getSignedHeadersString:request.allHTTPHeaderFields]];
    NSString *signatureAuthorizationHeader = [NSString stringWithFormat:@"Signature=%@", [self hexEncode:[[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding]]];
    
    NSString *authorization = [NSString stringWithFormat:@"%@ %@, %@, %@",
                               AWSSignatureV4Algorithm,
                               credentialsAuthorizationHeader,
                               signedHeadersAuthorizationHeader,
                               signatureAuthorizationHeader];
    
    [request addValue:authorization forHTTPHeaderField:@"Authorization"];
}

@end
