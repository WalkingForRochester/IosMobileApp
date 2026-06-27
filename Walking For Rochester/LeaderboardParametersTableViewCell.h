//
//  LeaderboardParametersTableViewCell.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import <UIKit/UIKit.h>

// Must have same values as corresponding segment indices in UISegmented control.
typedef enum {
    kLeaderboardParametersTableViewCellSortOrderCollection = 0,
    kLeaderboardParametersTableViewCellSortOrderDistance,
    kLeaderboardParametersTableViewCellSortOrderDuration
} LeaderboardParametersTableViewCellSortOrder;

// Must have same values as corresponding segment indices in UISegmented control.
typedef enum {
    kLeaderboardParametersTableViewCellDelegateIntervalDay = 0,
    kLeaderboardParametersTableViewCellDelegateIntervalWeek,
    kLeaderboardParametersTableViewCellDelegateIntervalMonth,
    kLeaderboardParametersTableViewCellDelegateIntervalYear
} LeaderboardParametersTableViewCellInterval;

@protocol LeaderboardParametersTableViewCellDelegate;

@interface LeaderboardParametersTableViewCell : UITableViewCell

@property (weak, nonatomic) id<LeaderboardParametersTableViewCellDelegate> delegate;
@property (assign, nonatomic) LeaderboardParametersTableViewCellSortOrder sortOrder;
@property (assign, nonatomic) LeaderboardParametersTableViewCellInterval interval;

@end

@protocol LeaderboardParametersTableViewCellDelegate

- (void)leaderboardParametersTableViewCell:(LeaderboardParametersTableViewCell *)leaderboardParametersTableViewCell sortOrderChanged:(LeaderboardParametersTableViewCellSortOrder)sortOrder;

- (void)leaderboardParametersTableViewCell:(LeaderboardParametersTableViewCell *)leaderboardParametersTableViewCell intervalChanged:(LeaderboardParametersTableViewCellInterval)interval;

@end
