//
//  LeaderboardEntry.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import "APIObject.h"
#import "APIManager.h"

@interface LeaderboardEntry : APIObject

@property (strong, nonatomic, readonly) NSNumber *place;
@property (strong, nonatomic, readonly) APIManagerAccountID *accountId;
@property (strong, nonatomic, readonly) NSString *firstName;
@property (strong, nonatomic, readonly) NSString *nickname;
@property (strong, nonatomic, readonly) NSURL *imgUrl;
@property (strong, nonatomic, readonly) NSNumber *collection;
@property (strong, nonatomic, readonly) NSNumber *distance;
@property (strong, nonatomic, readonly) NSNumber *duration;

@end

