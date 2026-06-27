//
//  LeaderboardParametersTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import "LeaderboardParametersTableViewCell.h"

@interface LeaderboardParametersTableViewCell ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *sortOrderSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *intervalSegmentedControl;
@end

@implementation LeaderboardParametersTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    UIFont *customFont = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    NSDictionary *attributes = @{NSFontAttributeName: customFont};
    [_sortOrderSegmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [_intervalSegmentedControl setTitleTextAttributes:attributes forState:UIControlStateNormal];
    _sortOrderSegmentedControl.selectedSegmentIndex = _sortOrder;
    _intervalSegmentedControl.selectedSegmentIndex = _interval;
}

- (void)setSortOrder:(LeaderboardParametersTableViewCellSortOrder)sortOrder
{
    _sortOrder = sortOrder;
    _sortOrderSegmentedControl.selectedSegmentIndex = sortOrder;
}
 
- (void)setInterval:(LeaderboardParametersTableViewCellInterval)interval
{
    _interval = interval;
    _intervalSegmentedControl.selectedSegmentIndex = interval;
}

- (IBAction)sortOrderChanged:(id)sender
{
    _sortOrder = (LeaderboardParametersTableViewCellSortOrder)_sortOrderSegmentedControl.selectedSegmentIndex;
    [_delegate leaderboardParametersTableViewCell:self sortOrderChanged:_sortOrder];
}

- (IBAction)intervalChanged:(id)sender
{
    _interval = (LeaderboardParametersTableViewCellInterval)_intervalSegmentedControl.selectedSegmentIndex;
    [_delegate leaderboardParametersTableViewCell:self intervalChanged:_interval];
}


@end
