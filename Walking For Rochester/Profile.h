//
//  Profile.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import "APIObject.h"
#import "APIManager.h"

@interface Profile : APIObject

@property (strong, nonatomic, readonly) APIManagerAccountID *accountId;
@property (strong, nonatomic, readonly) NSString *nickname;
@property (strong, nonatomic, readonly) NSString *email;
@property (strong, nonatomic, readonly) NSString *phoneNumber;
@property (assign, nonatomic, readonly) BOOL communityService;
@property (strong, nonatomic, readonly) NSURL *imgUrl;
@property (strong, nonatomic, readonly) NSString *facebookId;
@property (strong, nonatomic, readonly) NSNumber *distance;
@property (strong, nonatomic, readonly) NSNumber *totalDistance;
@property (strong, nonatomic, readonly) NSNumber *duration;
@property (strong, nonatomic, readonly) NSNumber *totalDuration;

@end

@interface ProfileUpdate : NSObject

@property (strong, nonatomic, readonly) APIManagerAccountID *accountId;
@property (strong, nonatomic) NSString *nickname;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *phone;  // The underlying JSON key has a different name from what it has in Profile. This name must be the same as the JSON key.
@property (assign, nonatomic) BOOL communityService;
@property (strong, nonatomic) NSURL *imgUrl;

@property (strong, nonatomic, readonly) NSDictionary<NSString *, NSObject *> *dictionary;

@end
