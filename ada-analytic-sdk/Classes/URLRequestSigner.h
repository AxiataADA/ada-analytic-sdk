//
//  URLRequestSigner.h
//  ADAAnalytics
//
//  Created by Chavalit Vanasapdamrong on 18/6/2561 BE.
//

#import <Foundation/Foundation.h>

@interface URLRequestSigner : NSObject

- (void)signRequest:(NSMutableURLRequest *)signedRequest secretSigningKey:(NSString *)secretSigningKey accessKeyId:(NSString *)accessKeyId apiKey:(NSString *)apiKey;

@end
