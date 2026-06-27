//
//  LeaderboardEntry.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import "LeaderboardEntry.h"

@implementation LeaderboardEntry

@dynamic place, accountId, firstName, nickname, imgUrl, collection, distance, duration;

- (NSNumber *)place
{
    return (NSNumber *)[self numberWithKey:NSStringFromSelector(_cmd)];
}

- (APIManagerAccountID *)accountId
{
    return (APIManagerAccountID *)[self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSString *)firstName
{
    return [self stringWithKey:NSStringFromSelector(_cmd)];
}

- (NSString *)nickname
{
    return [self stringWithKey:NSStringFromSelector(_cmd)];
}

- (NSURL *)imgUrl
{
    return [self urlWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)collection
{
    // Oddly, this value is in the JSON from the server as a string.
    NSString *collectionString = [self stringWithKey:NSStringFromSelector(_cmd)];
    return @([collectionString integerValue]);
}

- (NSNumber *)distance
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)duration
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

@end
