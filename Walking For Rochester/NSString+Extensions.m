//
//  NSString+Extensions.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/26/26.
//

#import <CommonCrypto/CommonDigest.h>
#import "NSString+Extensions.h"

@implementation NSString (Extensions)

- (NSString *)decimalDigits
{
    return [[self componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet].invertedSet] componentsJoinedByString:@""];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (NSString *)md5Hash
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

    const char *p = [self UTF8String];
    CC_MD5(p, (CC_LONG)strlen(p), md5Buffer);

    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
        [hash appendFormat:@"%02x", md5Buffer[i]];

    return hash;
}
#pragma clang diagnostic pop

- (BOOL)isValidEmailAddress
{
    static NSRegularExpression *emailFinder;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        emailFinder = [NSRegularExpression regularExpressionWithPattern:@"[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,6}" options:NSRegularExpressionCaseInsensitive error:&error];
        NSAssert(error == nil && emailFinder != nil, @"Bad regex for email finding");
    });
    
    NSRange range = NSMakeRange(0, self.length);
    return NSEqualRanges([emailFinder rangeOfFirstMatchInString:self options:0 range:range], range);
}

@end
