//
//  ProfileStatisticsTableViewCell.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import <UIKit/UIKit.h>

typedef enum  {
    kProfileStatisticsTableViewCellTypeDistance,
    kProfileStatisticsTableViewCellTypeDuration
} ProfileStatisticsTableViewCellType;

@class Profile;

@interface ProfileStatisticsTableViewCell : UITableViewCell

+ (NSNumber *)distanceInMilesFromMeters:(NSNumber *)distanceInMeters;

+ (NSString *)formatDistanceInMeters:(NSNumber *)distanceInMeters;

+ (NSString *)formatDistanceInMiles:(NSNumber *)distanceInMiles;

+ (NSString *)formatDurationInMilliseconds:(NSNumber *)durationInMilliseconds;

+ (NSString *)formatDurationInSeconds:(NSNumber *)durationInMilliseconds;

- (void)setProfile:(Profile *)profile type:(ProfileStatisticsTableViewCellType)type;

@property (assign, nonatomic, readonly) ProfileStatisticsTableViewCellType type;
@property (strong, nonatomic, readonly) Profile *profile;

@end
