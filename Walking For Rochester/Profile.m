//
//  Profile.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import "Profile.h"
#import "APIManager.h"

@implementation Profile

@dynamic accountId, nickname, email, communityService, imgUrl, facebookId, distance, totalDistance, duration, totalDuration;

- (APIManagerAccountID *)accountId
{
    return (APIManagerAccountID *)[self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSString *)nickname
{
    return [self stringWithKey:NSStringFromSelector(_cmd)];
}

- (NSString *)email
{
    return [self stringWithKey:NSStringFromSelector(_cmd)];
}

- (BOOL)communityService
{
    return [self numberWithKey:NSStringFromSelector(_cmd)].boolValue;
}

- (NSURL *)imgUrl
{
    return [self urlWithKey:NSStringFromSelector(_cmd)];
}

- (NSString *)facebookId
{
    return [self stringWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)distance
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)totalDistance
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)duration
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

- (NSNumber *)totalDuration
{
    return [self numberWithKey:NSStringFromSelector(_cmd)];
}

@end

@interface ProfileUpdate ()
{
    NSMutableDictionary<NSString *, NSObject *> *_params;
}

@property (strong, nonatomic) APIManagerAccountID *accountId;

@end

@implementation ProfileUpdate

@dynamic accountId, nickname, email, communityService, imgUrl, dictionary;

- (id)init
{
    if ((self = [super init]) != nil) {
        _params = [NSMutableDictionary dictionaryWithCapacity:10];
        self.accountId = [APIManager sharedAPIManager].accountId;
    }
    return self;
}

- (void)setParamFromSelector:(SEL)selector value:(NSObject *)value
{
    NSString *cmd = NSStringFromSelector(selector);
    NSAssert([cmd hasPrefix:@"set"], @"Expected a set command");
    NSAssert([cmd hasSuffix:@":"], @"Expected a set command ending in ':'");
    NSString *key = [NSString stringWithFormat:@"%@%@", [cmd substringWithRange:NSMakeRange(3, 1)].lowercaseString, [cmd substringWithRange:NSMakeRange(4, cmd.length - 5)]];
    if (value != nil)
        _params[key] = value;
    else
        [_params removeObjectForKey:key];
}

- (void)setAccountId:(APIManagerAccountID *)accountId
{
    NSAssert(accountId != nil, @"Expected an accountId");
    [self setParamFromSelector:_cmd value:accountId];
}

- (APIManagerAccountID *)accountId
{
    return (APIManagerAccountID *)_params[NSStringFromSelector(_cmd)];
}

- (void)setNickname:(NSString *)nickname
{
    [self setParamFromSelector:_cmd value:nickname];
}

- (NSString *)nickname
{
    return (NSString *)_params[NSStringFromSelector(_cmd)];
}

- (void)setEmail:(NSString *)email
{
    [self setParamFromSelector:_cmd value:email];
}

- (NSString *)email
{
    return (NSString *)_params[NSStringFromSelector(_cmd)];
}

- (void)setCommunityService:(BOOL)communityService
{
    [self setParamFromSelector:_cmd value:[NSNumber numberWithBool:communityService]];
}

- (BOOL)communityService
{
    return ((NSNumber *)_params[NSStringFromSelector(_cmd)]).boolValue;
}

- (void)setImgUrl:(NSURL *)imgUrl
{
    [self setParamFromSelector:_cmd value:imgUrl.absoluteString];
}

- (NSURL *)imgUrl
{
    NSString *urlStr = (NSString *)_params[NSStringFromSelector(_cmd)];
    return urlStr != nil ? [NSURL URLWithString:urlStr] : nil;
}

- (NSDictionary<NSString *, NSObject *> *)dictionary
{
    return [NSDictionary dictionaryWithDictionary:_params];
}

@end
