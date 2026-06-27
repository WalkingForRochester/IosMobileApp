//
//  ProfileStatisticsTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import "ProfileStatisticsTableViewCell.h"
#import "Profile.h"

@interface ProfileStatisticsTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastWalkStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *overallStatsLabel;

@end

@implementation ProfileStatisticsTableViewCell

+ (NSNumber *)distanceInMilesFromMeters:(NSNumber *)distanceInMeters
{
    return @([distanceInMeters doubleValue] / 1609.344);
}

+ (NSString *)formatDistanceInMeters:(NSNumber *)distanceInMeters
{
    return [self formatDistanceInMiles:[self distanceInMilesFromMeters:distanceInMeters]];
}

+ (NSString *)formatDistanceInMiles:(NSNumber *)distanceInMiles
{
    return [NSString stringWithFormat:@"%0.2f mi", [distanceInMiles doubleValue]];
}

+ (NSString *)formatDurationInMilliseconds:(NSNumber *)durationInMilliseconds
{
    return [self formatDurationInSeconds:@([durationInMilliseconds doubleValue] / 1000)];
}

+ (NSString *)formatDurationInSeconds:(NSNumber *)durationInSeconds
{
    NSTimeInterval interval = floor([durationInSeconds doubleValue]);
    NSDateComponentsFormatter *formatter = [NSDateComponentsFormatter new];
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    if (interval >= 3600)
        formatter.allowedUnits |= NSCalendarUnitHour;
    return [formatter stringFromTimeInterval:interval];
}

- (void)setProfile:(Profile *)profile type:(ProfileStatisticsTableViewCellType)type
{
    _profile = profile;
    _type = type;
    if (type == kProfileStatisticsTableViewCellTypeDistance) {
        _titleLabel.text = @"Distances";
        _lastWalkStatsLabel.text = [self.class formatDistanceInMeters:profile.distance];
        _overallStatsLabel.text = [self.class formatDistanceInMeters:profile.totalDistance];
    }
    else {
        _titleLabel.text = @"Durations";
        _lastWalkStatsLabel.text = [self.class formatDurationInMilliseconds:profile.duration];
        _overallStatsLabel.text = [self.class formatDurationInMilliseconds:profile.totalDuration];
    }
}

@end
