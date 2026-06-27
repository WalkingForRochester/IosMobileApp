//
//  APIObject.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import "APIObject.h"

@implementation APIObject

- (id)initWithDictionary:(NSDictionary<NSString *, NSObject *> *)dictionary
{
    if ((self = [super init]) != nil)
        _dictionary = dictionary;
    return self;
}

- (NSNumber *)numberWithKey:(NSString *)key
{
    NSObject *obj = _dictionary[key];
    return [obj isKindOfClass:[NSNumber class]] ? (NSNumber *)obj : nil;
}

- (NSString *)stringWithKey:(NSString *)key
{
    NSObject *obj = _dictionary[key];
    return [obj isKindOfClass:[NSString class]] ? (NSString *)obj : nil;
}

- (NSURL *)urlWithKey:(NSString *)key
{
    NSString *string = [self stringWithKey:key];
    return string != nil ? [NSURL URLWithString:string] : nil;
}

- (NSString *)description
{
    return [self.dictionary description];
}

@end
