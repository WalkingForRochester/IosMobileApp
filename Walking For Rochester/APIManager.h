//
//  APIManager.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/24/26.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#define kAPIManagerMinPasswordLength 8

typedef NSNumber APIManagerAccountID;

@class Profile;
@class ProfileUpdate;
@class LeaderboardEntry;

typedef enum {
    kAPIManagerImageFileTypeProfile,
    kAPIManagerImageFileTypeLitter
} APIManagerImageFileType;

@interface APIManagerCall : NSObject

- (void)showErrorForViewController:(UIViewController *)viewController;

+ (void)showError:(NSError *)error forViewController:(UIViewController *)viewController;

@end

@interface APIManager : NSObject

+ (instancetype)sharedAPIManager;

- (APIManagerCall *)accountByEmail:(NSString *)email completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion;

- (APIManagerCall *)signUpWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email displayName:(NSString *)displayName password:(NSString *)password isCommunityService:(BOOL)isCommunityService completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion;

- (APIManagerCall *)signInWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error))completion;

- (APIManagerCall *)forgotPasswordWithEmail:(NSString *)email completion:(void (^)(APIManagerCall *call, NSString *code, NSError *error))completion;

- (APIManagerCall *)resetPasswordWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion;

- (APIManagerCall *)getUserProfileWithCompletion:(void (^)(APIManagerCall *call, Profile *profile, NSError *error))completion;

- (APIManagerCall *)getUserProfileWithAccountId:(APIManagerAccountID *)accountId completion:(void (^)(APIManagerCall *call, Profile *profile, NSError *error))completion;

- (APIManagerCall *)deleteUserWithCompletion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion;

- (APIManagerCall *)deleteUserWithAccountId:(APIManagerAccountID *)accountId completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion;

- (APIManagerCall *)uploadImageWithType:(APIManagerImageFileType)type data:(NSData *)data completion:(void (^)(APIManagerCall *call, NSURL *imgUrl, NSError *error))completion;

- (APIManagerCall *)updateProfileWith:(ProfileUpdate *)profileUpdate completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion;

- (APIManagerCall *)getLeaderboardFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate timeZone:(NSTimeZone *)timeZone completion:(void (^)(APIManagerCall *call, NSArray<LeaderboardEntry *> *entries, NSError *error))completion;

- (APIManagerCall *)logWalkWithDistance:(CLLocationDistance)distance duration:(NSTimeInterval)duration bags:(NSUInteger)bags imageUrl:(NSURL *)imageUrl encodedPath:(NSString *)encodedPath completion:(void (^)(APIManagerCall *call, BOOL succeeded, NSError *error))completion;

@property (strong, nonatomic) APIManagerAccountID *accountId;

@end

