//
//  LeaderboardEntryTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/28/26.
//

#import "LeaderboardEntryTableViewCell.h"
#import "LeaderboardParametersTableViewCell.h"
#import "LeaderboardEntry.h"
#import "RoundImageView.h"
#import "ImageLoader.h"
#import "ProfileStatisticsTableViewCell.h"

static NSArray<UIColor *> *s_rankedColors;

@interface LeaderboardEntryTableViewCell ()
{
    ImageLoader *_imageLoader;
    NSArray<UIColor *> *_rankedColors;
}

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *rankLabel;
@property (weak, nonatomic) IBOutlet RoundImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

@implementation LeaderboardEntryTableViewCell

+ (void)load
{
    s_rankedColors = @[
        [UIColor colorNamed:@"color_leaderboard_rank_0"],
        [UIColor colorNamed:@"color_leaderboard_rank_1"],
        [UIColor colorNamed:@"color_leaderboard_rank_2"],
        [UIColor colorNamed:@"color_leaderboard_rank_3+"],
    ];
}

- (void)setLeaderboarEntry:(LeaderboardEntry *)leaderboardEntry rankIndex:(NSUInteger)rankIndex sortOrder:(LeaderboardParametersTableViewCellSortOrder)sortOrder
{
    _leaderboardEntry = leaderboardEntry;
    _rankIndex = rankIndex;
    _sortOrder = sortOrder;
    _rankLabel.text = [NSString stringWithFormat:@"%lu", rankIndex + 1];
    _imageLoader = [ImageLoader new];
    _containerView.backgroundColor = s_rankedColors[MIN(rankIndex, s_rankedColors.count - 1)];
    _profileImageView.image = nil;
    NSURL *imageUrl = leaderboardEntry.imgUrl;
    if (imageUrl != nil) {
        WEAK_SELF_PTR;
        [_imageLoader loadImageAtURL:imageUrl completion:^(UIImage *image) {
            weakSelf.profileImageView.image = image;
        }];
    }
    NSString *name = leaderboardEntry.nickname;
    if (name.length == 0)
        name = leaderboardEntry.firstName;
    _nameLabel.text = name;
    NSString *value = nil;
    switch (sortOrder) {
        case kLeaderboardParametersTableViewCellSortOrderCollection:
            value = [NSString stringWithFormat:@"%@", leaderboardEntry.collection];
            break;
        case kLeaderboardParametersTableViewCellSortOrderDistance:
            value = [ProfileStatisticsTableViewCell formatDistanceInMiles:leaderboardEntry.distance];
            break;
        case kLeaderboardParametersTableViewCellSortOrderDuration:
            value = [ProfileStatisticsTableViewCell formatDurationInMilliseconds:leaderboardEntry.duration];
            break;
    }
    _valueLabel.text = value;
}

@end
