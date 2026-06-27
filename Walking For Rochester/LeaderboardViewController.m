//
//  LeaderboardViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import "LeaderboardViewController.h"
#import "APIManager.h"
#import "LeaderboardEntry.h"
#import "LeaderboardParametersTableViewCell.h"
#import "LeaderboardEntryTableViewCell.h"
#import "MainViewController.h"

typedef enum {
    kSectionParameters = 0,
    kSectionLeaders,
    kNumSections
} Section;

@interface LeaderboardViewController () <UITableViewDelegate, UITableViewDataSource, LeaderboardParametersTableViewCellDelegate>
{
    LeaderboardParametersTableViewCellSortOrder _sortOrder;
    LeaderboardParametersTableViewCellInterval _interval;
    NSArray<LeaderboardEntry *> *_entries;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation LeaderboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _sortOrder = kLeaderboardParametersTableViewCellSortOrderCollection;
    _interval = kLeaderboardParametersTableViewCellDelegateIntervalWeek;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _tableView.contentInset = [[MainViewController sharedMainViewController] edgeInsetsForView:_tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    _entries = nil;
    [_tableView reloadData];
}

- (void)refresh
{
    NSDate *endDate = [NSDate now];
    NSDate *startDate = nil;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    switch (_interval) {
        case kLeaderboardParametersTableViewCellDelegateIntervalDay:
            startDate = endDate;
            break;
        case kLeaderboardParametersTableViewCellDelegateIntervalWeek:
            startDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:endDate options:0];
            break;
        case kLeaderboardParametersTableViewCellDelegateIntervalMonth:
            startDate = [calendar dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:endDate options:0];
            break;
        case kLeaderboardParametersTableViewCellDelegateIntervalYear:
            startDate = [calendar dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:endDate options:0];
            break;
    }
    NSAssert(startDate != nil, @"Expected a start date");
    WEAK_SELF_PTR;
    [[APIManager sharedAPIManager] getLeaderboardFromStartDate:startDate toEndDate:endDate timeZone:calendar.timeZone completion:^(APIManagerCall *call, NSArray<LeaderboardEntry *> *entries, NSError *error) {
        [weakSelf sortAndDisplayEntries:entries];
    }];
}

- (void)sortAndDisplayEntries:(NSArray<LeaderboardEntry *> *)entries
{
    LeaderboardParametersTableViewCellSortOrder sortOrder = _sortOrder;
    BOOL hadEntries = _entries.count != 0;
    _entries = [entries sortedArrayUsingComparator:^NSComparisonResult(LeaderboardEntry *obj1, LeaderboardEntry *obj2) {
        NSComparisonResult result = NSOrderedSame;
        switch (sortOrder) {
            case kLeaderboardParametersTableViewCellSortOrderCollection:
                result = [obj2.collection compare:obj1.collection];
                break;
            case kLeaderboardParametersTableViewCellSortOrderDistance:
                result = [obj2.distance compare:obj1.distance];
                break;
            case kLeaderboardParametersTableViewCellSortOrderDuration:
                result = [obj2.duration compare:obj1.duration];
                break;
        }
        if (result == NSOrderedSame) {
            NSString *name1 = obj1.nickname;
            if (name1.length == 0)
                name1 = obj1.firstName;
            NSString *name2 = obj2.nickname;
            if (name2.length == 0)
                name2 = obj2.firstName;
            result = [name1 compare:name2];
            if (result == NSOrderedSame)
                result = [obj1.accountId compare:obj2.accountId];
        }
        return result;
    }];
    BOOL hasEntries = _entries.count != 0;
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSetWithIndex:kSectionLeaders];
    if (hasEntries != hadEntries)
        [indexSet addIndex:kSectionParameters];
    
    [_tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case kSectionParameters:
            return _entries.count > 0 ? 1 : 0;
        case kSectionLeaders:
            return _entries.count;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Section section = (Section)indexPath.section;
    if (section == kSectionParameters) {
        LeaderboardParametersTableViewCell *cell = (LeaderboardParametersTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LeaderboardParametersTableViewCell"];
        cell.delegate = self;
        cell.sortOrder = _sortOrder;
        cell.interval = _interval;
        return cell;
    }
    else if (section == kSectionLeaders) {
        LeaderboardEntryTableViewCell *cell = (LeaderboardEntryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LeaderboardEntryTableViewCell"];
        NSUInteger row = indexPath.row;
        [cell setLeaderboarEntry:_entries[row] rankIndex:row sortOrder:_sortOrder];
        return cell;
    }
    return nil;
}

- (void)leaderboardParametersTableViewCell:(LeaderboardParametersTableViewCell *)leaderboardParametersTableViewCell sortOrderChanged:(LeaderboardParametersTableViewCellSortOrder)sortOrder
{
    _sortOrder = sortOrder;
    [self sortAndDisplayEntries:_entries];
}

- (void)leaderboardParametersTableViewCell:(LeaderboardParametersTableViewCell *)leaderboardParametersTableViewCell intervalChanged:(LeaderboardParametersTableViewCellInterval)interval
{
    _interval = interval;
    [self refresh];
}

@end
