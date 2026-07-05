//
//  ProfileViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/12/26.
//

#import "ProfileViewController.h"
#import "Profile.h"
#import "APIManager.h"
#import "ProfileUserTableViewCell.h"
#import "ProfileStatisticsTableViewCell.h"
#import "ProfileAccountTableViewCell.h"
#import "ProfileEditorViewController.h"
#import "HomeViewController.h"
#import "MainViewController.h"

typedef enum {
    kSectionProfile = 0,
    kSectionAccount,
    kNumSections
} SectionType;

typedef enum {
    kCellProfile = 0,
    kCellDistance,
    kCellDuration,
    kCellDisclaimer,
    kNumProfileCells
} ProfileCellType;

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, ProfileAccountTableViewCellDelegate>
{
    APIManagerCall *_loadProfileCall;
    UIAlertAction __weak *_deleteAction;
}

@property (strong, nonatomic) Profile *profile;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ProfileViewController

@dynamic hiddenBackButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([MainViewController sharedMainViewController].isSmallScreen) {
        _tableView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
        _tableView.sectionHeaderHeight /= 2;
        _tableView.sectionFooterHeight /= 2;
    }
    [self refresh];
}

- (void)refresh
{
    if (_loadProfileCall == nil) {
        WEAK_SELF_PTR;
        _loadProfileCall = [[APIManager sharedAPIManager] getUserProfileWithCompletion:^(APIManagerCall *call, Profile *profile, NSError *error) {
            [weakSelf didLoadProfileWithCall:call profile:profile error:error];
        }];
    }
}


- (void)didLoadProfileWithCall:(APIManagerCall *)call profile:(Profile *)profile error:(NSError *)error
{
    if (call == _loadProfileCall) {
        _loadProfileCall = nil;
        self.profile = profile;
    }
}

- (void)setProfile:(Profile *)profile
{
    _profile = profile;
    [_tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _profile != nil ? kNumSections : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_profile != nil) {
        if (section == kSectionProfile)
            return kNumProfileCells;
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SectionType section = (SectionType)indexPath.section;
    if (section == kSectionProfile) {
        ProfileCellType type = (ProfileCellType)indexPath.row;
        switch (type) {
            case kCellProfile:
            {
                ProfileUserTableViewCell *cell = (ProfileUserTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileUserTableViewCell"];
                cell.profile = _profile;
                cell.profileViewController = self;
                return cell;
            }
            case kCellDistance:
            case kCellDuration:
            {
                ProfileStatisticsTableViewCell *cell = (ProfileStatisticsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileStatisticsTableViewCell"];
                [cell setProfile:_profile type:type == kCellDistance ? kProfileStatisticsTableViewCellTypeDistance : kProfileStatisticsTableViewCellTypeDuration];
                return cell;
            }
            case kCellDisclaimer:
                return [tableView dequeueReusableCellWithIdentifier:@"ProfileDisclaimerTableViewCell"];
            default:
                break;
        }
    }
    else if (section == kSectionAccount) {
        ProfileAccountTableViewCell *cell = (ProfileAccountTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ProfileAccountTableViewCell"];
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (void)profileAccountTableViewCellDidDeleteAccount:(ProfileAccountTableViewCell *)profileAccountTableViewCell
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete account" message:@"Sorry to see you go. By continuing, your account and all walk history will be deleted from Walking for Rochester." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    WEAK_SELF_PTR;
    [alert addAction:_deleteAction = [UIAlertAction actionWithTitle:@"Delete account" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf doDeleteAccount];
    }]];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Type \"YES\" to confirm";
        [textField addTarget:weakSelf action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    _deleteAction.enabled = NO;
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    NSString *text = [[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    textField.text = text;
    _deleteAction.enabled = [text isEqualToString:@"YES"];
}

- (void)doDeleteAccount
{
    WEAK_SELF_PTR;
    APIManager *manager = [APIManager sharedAPIManager];
    [[APIManager sharedAPIManager] deleteUserWithCompletion:^(APIManagerCall *call, BOOL succeeded, NSError *error) {
        if (succeeded) {
            manager.accountId = nil;
            [weakSelf returnToLoginScreen];
        }
    }];
}

- (void)profileAccountTableViewCellDidLogout:(ProfileAccountTableViewCell *)profileAccountTableViewCell
{
    [APIManager sharedAPIManager].accountId = nil;
    [self returnToLoginScreen];
}

- (void)returnToLoginScreen
{
    [[HomeViewController sharedHomeViewController] popToViewControllerWithClass:[MainViewController class] animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *target = segue.destinationViewController;
    
    if ([target isKindOfClass:[ProfileEditorViewController class]]) {
        ProfileEditorViewController *editor = (ProfileEditorViewController *)target;
        editor.profileViewController = self;
    }
}

- (void)setHiddenBackButton:(BOOL)hiddenBackButton
{
    [MainViewController sharedMainViewController].navigationController.topViewController.navigationItem.hidesBackButton = hiddenBackButton;
}

- (BOOL)hiddenBackButton
{
    return [MainViewController sharedMainViewController].navigationController.topViewController.navigationItem.hidesBackButton;
}

@end
