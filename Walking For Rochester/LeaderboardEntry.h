//
//  LeaderboardEntry.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import "APIObject.h"
#import "APIManager.h"


/*
 "place": 1,
     "accountId": 10000319,
     "firstName": "Kristie",
     "nickname": "Kristie",
     "imgUrl": "https:\/\/walkingforrochester.com\/images\/default_img.png",
     "collection": "104",
     "distance": 60.414888326027594,
     "duration": 180117463
 */
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

