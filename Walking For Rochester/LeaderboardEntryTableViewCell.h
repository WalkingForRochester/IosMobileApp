//
//  LeaderboardEntryTableViewCell.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/28/26.
//

#import <UIKit/UIKit.h>
#import "LeaderboardEntry.h"
#import "LeaderboardParametersTableViewCell.h"

@interface LeaderboardEntryTableViewCell : UITableViewCell

- (void)setLeaderboarEntry:(LeaderboardEntry *)leaderboardEntry rankIndex:(NSUInteger)rankIndex sortOrder:(LeaderboardParametersTableViewCellSortOrder)sortOrder;

@property (strong, nonatomic, readonly) LeaderboardEntry *leaderboardEntry;
@property (assign, nonatomic, readonly) NSUInteger rankIndex;
@property (assign, nonatomic, readonly) LeaderboardParametersTableViewCellSortOrder sortOrder;

@end
