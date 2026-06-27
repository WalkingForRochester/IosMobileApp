//
//  NSCache+Extensions.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/29/26.
//

#import "NSCache+Extensions.h"

@implementation NSCache (Extensions)

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key
{
    if (obj != nil)
        [self setObject:obj forKey:key];
    else
        [self removeObjectForKey:key];
}

@end
