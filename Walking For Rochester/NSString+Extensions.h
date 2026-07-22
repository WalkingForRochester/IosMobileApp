//
//  NSString+Extensions.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/26/26.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)

- (NSString *)decimalDigits;

- (NSString *)md5Hash;

- (BOOL)isValidEmailAddress;

@end

