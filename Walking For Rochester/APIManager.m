//
//  APIManager.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/24/26.
//

#import "APIManager.h"
#import "Secrets.h"
#import "RootViewController.h"
#import "Profile.h"
#import "LeaderboardEntry.h"
#import "NSString+Extensions.h"
#import "ProfileStatisticsTableViewCell.h"

#define kKeyAccountId @"accountId"
#define kHttpPath @"https://walkingforrochester.com/php/v2"
#define kProfileImagePath @"https://walkingforrochester.com/images/profile"
#define kPickImagePath @"https://walkingforrochester.com/images/walking"

typedef enum {
    kAPIManagerCallMethodPost
} APIManagerCallMethod;

@interface APIManagerCall ()
{
    NSURLRequest *_request;
    NSURLSessionDataTask *_dataTask;
}

@end

@interface APIManager () <NSURLSessionDelegate>
{
    NSMutableSet<APIManagerCall *> *_callsInProgress;
}

- (void)addCallInProgress:(APIManagerCall *)call;
- (void)removeCallInProgress:(APIManagerCall *)call;

@property (strong, nonatomic, readonly) NSURLSession *session;

@end

@implementation APIManagerCall

+ (NSMutableURLRequest *)requestWithPath:(NSString *)path method:(APIManagerCallMethod)method
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", kHttpPath, path]]];
    //[request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setValue:API_KEY forHTTPHeaderField:@"wfr-auth-token"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    if (method == kAPIManagerCallMethodPost)
        request.HTTPMethod = @"POST";
    return request;
}

- (id)initWithPath:(NSString *)path params:(NSDictionary<NSString *, NSObject *> *)params method:(APIManagerCallMethod)method
{
    if ((self = [super init]) != nil) {
        NSMutableURLRequest *request = [self.class requestWithPath:path method:kAPIManagerCallMethodPost];
        if (method == kAPIManagerCallMethodPost) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];
            request.HTTPBody = jsonData;
            [request setValue:[NSString stringWithFormat:@"%lu", jsonData.length] forHTTPHeaderField:@"Content-Length"];
            [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        }
        _request = request;
    }
    return self;
}

- (id)initWithPath:(NSString *)path fileName:(NSString *)fileName data:(NSData *)data
{
    if ((self = [super init]) != nil) {
        NSMutableURLRequest *request = [self.class requestWithPath:path method:kAPIManagerCallMethodPost];
        NSString *boundary = [[NSUUID UUID].UUIDString lowercaseString];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSString *header = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n\r\n", boundary, fileName];
        NSData *headerData = [header dataUsingEncoding:NSUTF8StringEncoding];
        NSString *footer = [NSString stringWithFormat:@"\r\n--%@--\r\n", boundary];
        NSData *footerData = [footer dataUsingEncoding:NSUTF8StringEncoding];
        NSUInteger contentLength = headerData.length + data.length + footerData.length;
        [request setValue:[NSString stringWithFormat:@"%lu", contentLength] forHTTPHeaderField:@"Content-Length"];
        NSMutableData *mData = [NSMutableData dataWithCapacity:contentLength];
        [mData appendData:headerData];
        [mData appendData:data];
        [mData appendData:footerData];
        NSAssert(mData.length == contentLength, @"Expected content length");
        request.HTTPBody = mData;
        _request = request;
    }
    return self;
}

- (void)runForManager:(APIManager *)manager completion:(void (^)(APIManagerCall *, NSData *, NSHTTPURLResponse *, NSError *))completion
{
    WEAK_SELF_PTR;
    NSURLRequest *request = _request;
    _dataTask = [manager.session dataTaskWithRequest:_request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [RootViewController sharedRootViewController].busyCount -= 1;
        APIManagerCall *strongSelf = weakSelf;
        [manager removeCallInProgress:strongSelf];
        NSHTTPURLResponse *urlResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
        NSLog(@"URL: %@\nbody:\n%@\nstatus: %ld\nerror:\n%@\nresponse:\n%@", request.URL.absoluteString, [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], urlResponse.statusCode, error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        completion(strongSelf, data, urlResponse, error);
    }];
    [manager addCallInProgress:self];
    [_dataTask resume];
    [RootViewController sharedRootViewController].busyCount += 1;
}

@end

@implementation APIManager

+ (instancetype)sharedAPIManager
{
    static APIManager *sharedManager;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedManager = [APIManager new];
    });
    
    return sharedManager;
}

- (id)init
{
    if ((self = [super init]) != nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        _callsInProgress = [NSMutableSet setWithCapacity:5];
        APIManagerAccountID *accountId = [[NSUserDefaults standardUserDefaults] objectForKey:kKeyAccountId];
        if ([accountId isKindOfClass:[APIManagerAccountID class]])
            _accountId = accountId;
    }
    return self;
}

- (void)setAccountId:(APIManagerAccountID *)accountId
{
    _accountId = accountId;
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    if (accountId != nil)
        [defs setValue:accountId forKey:kKeyAccountId];
    else
        [defs removeObjectForKey:kKeyAccountId];
    [defs synchronize];
}

- (void)addCallInProgress:(APIManagerCall *)call
{
    [_callsInProgress addObject:call];
}

- (void)removeCallInProgress:(APIManagerCall *)call
{
    [_callsInProgress removeObject:call];
}

- (APIManagerCall *)accountByEmail:(NSString *)email completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"email": email
    };
    
    WEAK_SELF_PTR;
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"accountByEmail.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        [weakSelf completeSignIn:NO withAPIManagerCall:call data:data response:response error:error completion:completion];
    }];
    
    return call;
}

+ (NSString *)formatDate
{
    return [self formatDate:[NSDate date]];
}

+ (NSString *)formatDate:(NSDate *)date
{
    return [self formatDate:date timeZone:[NSTimeZone localTimeZone]];
}

+ (NSString *)formatDate:(NSDate *)date timeZone:(NSTimeZone *)timeZone
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeZone = timeZone;
    formatter.dateFormat = @"yyyy-MM-dd";
    NSString *dateString = [formatter stringFromDate:date];
    NSAssert(dateString.length == @"0000-00-00".length, @"Formatted date has incorrect format");
    return dateString;
}

- (APIManagerCall *)signUpWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email phone:(NSString *)phone displayName:(NSString *)displayName password:(NSString *)password isCommunityService:(BOOL)isCommunityService completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"firstName": firstName,
        @"lastName": lastName,
        @"email": email,
        @"phone": phone,
        @"password": password,
        @"dateOfBirth": [self.class formatDate],
        @"nickname": displayName,
        @"communityService": @(isCommunityService)
    };
    
    WEAK_SELF_PTR;
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"registerAccount.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        [weakSelf completeSignIn:YES withAPIManagerCall:call data:data response:response error:error completion:completion];
    }];
    
    return call;
}

- (APIManagerCall *)signInWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"email": email,
        @"password": password
    };
    
    WEAK_SELF_PTR;
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"login.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        [weakSelf completeSignIn:YES withAPIManagerCall:call data:data response:response error:error completion:completion];
    }];
    
    return call;
}

- (void)completeSignIn:(BOOL)signIn withAPIManagerCall:(APIManagerCall *)call data:(NSData *)data response:(NSHTTPURLResponse *)response error:(NSError *)error completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion
{
    APIManagerAccountID *accountId = nil;
    NSString *errorText = nil;
    if (error == nil && data.length != 0) {
        NSDictionary<NSString *, NSObject *> *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error == nil && [dict isKindOfClass:[NSDictionary class]]) {
            NSObject *value = dict[@"accountId"];
            if ([value isKindOfClass:[APIManagerAccountID class]])
                accountId = (APIManagerAccountID *)value;
            value = dict[@"error"];
            if ([value isKindOfClass:[NSString class]])
                errorText = (NSString *)value;
        }
    }
    if (signIn)
        self.accountId = accountId;
    completion(call, accountId, errorText, error);
}

- (APIManagerCall *)forgotPasswordWithEmail:(NSString *)email completion:(void (^)(APIManagerCall *call, NSString *code, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"email": email
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"forgotPassword.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSString *code = nil;
        if (error == nil && data.length != 0) {
            NSDictionary<NSString *, NSObject *> *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error == nil && [dict isKindOfClass:[NSDictionary class]]) {
                NSObject *value = dict[@"code"];
                if ([value isKindOfClass:[NSString class]])
                    code = (NSString *)value;
            }
        }
        completion(call, code, error);
    }];
    
    return call;
}

- (APIManagerCall *)resetPasswordWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"email": email,
        @"password": password
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"resetPassword.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSInteger statusCode = response.statusCode;
        BOOL succeeded = error == nil && statusCode >= 200 && statusCode < 400;
        completion(call, succeeded, error);
    }];
    
    return call;
}

- (APIManagerCall *)getUserProfileWithCompletion:(void (^)(APIManagerCall *call, Profile *profile, NSError *error))completion
{
    return _accountId != nil ? [self getUserProfileWithAccountId:_accountId completion:completion] : nil;
}

- (APIManagerCall *)getUserProfileWithAccountId:(APIManagerAccountID *)accountId completion:(void (^)(APIManagerCall *call, Profile *profile, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"accountId": accountId
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"userProfile.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        Profile *profile = nil;
        if (error == nil && data.length != 0) {
            NSDictionary<NSString *, NSObject *> *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error == nil && [dict isKindOfClass:[NSDictionary class]])
                profile = [[Profile alloc] initWithDictionary:dict];
        }
        completion(call, profile, error);
    }];
    
    return call;
}

- (APIManagerCall *)deleteUserWithCompletion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion
{
    return _accountId != nil ? [self deleteUserWithAccountId:_accountId completion:completion] : nil;
}

- (APIManagerCall *)deleteUserWithAccountId:(APIManagerAccountID *)accountId completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"accountId": accountId
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"deleteUser.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSInteger statusCode = response.statusCode;
        BOOL succeeded = error == nil && statusCode >= 200 && statusCode < 400;
        completion(call, succeeded, error);
    }];
    
    return call;
};

- (APIManagerCall *)uploadImageWithType:(APIManagerImageFileType)type data:(NSData *)data completion:(void (^)(APIManagerCall *call, NSURL *imgUrl, NSError *error))completion
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    //formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    //formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone localTimeZone];
    formatter.dateFormat = @"MM_dd_yyyy_HH_mm_ss";
    NSString *dateString = [formatter stringFromDate:[NSDate now]];
    NSString *accountIdHash = [[NSString stringWithFormat:@"%@", self.accountId] md5Hash];
    NSString *prefix = type == kAPIManagerImageFileTypeProfile ? @"IMG_PROFILE" : @"IMG_WALKING_PICKIMAGE";
    NSString *fileName = [NSString stringWithFormat:@"%@_%@_%@", prefix, dateString, accountIdHash];
    NSLog(@"fileName is %@", fileName);
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"uploadImage.php" fileName:fileName data:data];
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSInteger statusCode = response.statusCode;
        NSURL *imgUrl = nil;
        if (error == nil && statusCode >= 200 && statusCode < 400 && data.length != 0) {
            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *expectedMessage = [NSString stringWithFormat:@"The file %@ has been uploaded.", fileName];
            if ([message isEqualToString:expectedMessage]) {
                NSString *urlStr = [NSString stringWithFormat:@"%@/%@.jpg", type == kAPIManagerImageFileTypeProfile ? kProfileImagePath : kPickImagePath, fileName];
                imgUrl = [NSURL URLWithString:urlStr];
            }
        }
        completion(call, imgUrl, error);
    }];
    
    return call;
}

- (APIManagerCall *)updateProfileWith:(ProfileUpdate *)profileUpdate completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion
{
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"updateProfile.php" params:profileUpdate.dictionary method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSInteger statusCode = response.statusCode;
        BOOL succeeded = error == nil && statusCode >= 200 && statusCode < 400;
        completion(call, succeeded, error);
    }];
    
    return call;
}

- (APIManagerCall *)getLeaderboardFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate timeZone:(NSTimeZone *)timeZone completion:(void (^)(APIManagerCall *call, NSArray<LeaderboardEntry *> *entries, NSError *error))completion
{
    NSDictionary<NSString *, NSObject *> *params = @{
        @"orderBy": @"collection",
        @"startDate": [self.class formatDate:startDate timeZone:timeZone],
        @"endDate": [self.class formatDate:endDate timeZone:timeZone],
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"leaderboard.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSMutableArray<LeaderboardEntry *> *leaderboardEntries = nil;
        if (error == nil && data.length != 0) {
            NSArray<NSDictionary *> *entries = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([entries isKindOfClass:[NSArray class]]) {
                leaderboardEntries = [NSMutableArray arrayWithCapacity:entries.count];
                for (NSDictionary<NSString *, NSObject *> *dictionary in entries)
                    if ([dictionary isKindOfClass:[NSDictionary class]])
                        [leaderboardEntries addObject:[[LeaderboardEntry alloc] initWithDictionary:dictionary]];
            }
        }
        completion(call, leaderboardEntries, error);
    }];
    
    return call;
}

- (APIManagerCall *)logWalkWithDistance:(CLLocationDistance)distance duration:(NSTimeInterval)duration bags:(NSUInteger)bags imageUrl:(NSURL *)imageUrl encodedPath:(NSString *)encodedPath completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion
{
    NSString *baseFileName = [[[imageUrl pathComponents] lastObject] stringByDeletingPathExtension];
    NSDictionary<NSString *, NSObject *> *params = @{
        @"accountId": _accountId,
        @"distance": [ProfileStatisticsTableViewCell distanceInMilesFromMeters:@(distance)],
        @"duration": @(duration * 1000),
        @"collect": @(bags),
        @"pickDate": [self.class formatDate],
        @"imageFileName": baseFileName,
        @"path": encodedPath
    };
    
    APIManagerCall *call = [[APIManagerCall alloc] initWithPath:@"logAWalk.php" params:params method:kAPIManagerCallMethodPost];
    
    [call runForManager:self completion:^(APIManagerCall *call, NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSInteger statusCode = response.statusCode;
        BOOL succeeded = error == nil && statusCode >= 200 && statusCode < 400;
        completion(call, succeeded, error);
    }];
    
    return call;
}

@end
