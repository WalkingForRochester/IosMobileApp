//
//  APIObject.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import <Foundation/Foundation.h>

@interface APIObject : NSObject

- (id)initWithDictionary:(NSDictionary<NSString *, NSObject *> *)dictionary;

- (NSNumber *)numberWithKey:(NSString *)key;
- (NSString *)stringWithKey:(NSString *)key;
- (NSURL *)urlWithKey:(NSString *)key;

@property (strong, nonatomic, readonly) NSDictionary<NSString *, NSObject *> *dictionary;

@end

