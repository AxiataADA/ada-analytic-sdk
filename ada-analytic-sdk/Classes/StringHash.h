//
//  StringHash.h
//  ADAAnalyticsStaticSDK
//
//  Created by Chavalit Vanasapdamrong on 10/7/2562 BE.
//  Copyright © 2562 ADA Thailand. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringHash)
- (NSString *)md5;
@end

@interface NSData (StringHash)
- (NSString*)md5;
@end
