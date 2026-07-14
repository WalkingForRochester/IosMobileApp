//
//  MainViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/5/26.
//

#import <SafariServices/SafariServices.h>
#import "MainViewController.h"
#import "RootViewController.h"
#import "LoginViewController.h"
#import "ProfileRootViewController.h"
#import "Profile.h"
#import "APIManager.h"
#import "LogWalkViewController.h"
#import "LeaderboardViewController.h"
#import "NewsFeedViewController.h"

static MainViewController __weak *s_sharedMainViewController;

@interface MainViewController () <UITabBarControllerDelegate>
{
    UITabBarController __weak *_tabBarController;
}

@property (strong, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation MainViewController

+ (MainViewController *)sharedMainViewController
{
    return s_sharedMainViewController;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]) != nil)
        s_sharedMainViewController = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    _isSmallScreen = [UIScreen mainScreen].bounds.size.height <= 700;    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    WEAK_SELF_PTR;
    APIManager *manager = [APIManager sharedAPIManager];
    if (manager.accountId == nil)
        [self showLoginScreen];
    else [manager getUserProfileWithCompletion:^(APIManagerCall *call, Profile *profile, NSError *error) {
        if (error == nil && profile != nil && profile.accountId == nil) {
            manager.accountId = nil;
            [weakSelf showLoginScreen];
        }
        else if (manager.accountId == nil)
            // If there's an error and we don't have an account ID for the user, then
            // we'll let them see the error. Otherwise, we fail silenty, because they
            // might have no internet access. We can keep using their current account ID.
            // This allows the user to log walk on devices that have no active service or
            // when they are in a poor service area.
            [call showErrorForViewController:self];
    }];
}

- (void)showLoginScreen
{
    [self performSegueWithIdentifier:@"LoginViewControllerShowSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *target = segue.destinationViewController;
    if ([target isKindOfClass:[UITabBarController class]]) {
        _tabBarController = (UITabBarController *)target;
        if (@available(iOS 26.0, *))
            _tabBarController.tabBar.translucent = YES;
        else
            _tabBarController.tabBar.translucent = NO;
        _tabBarController.delegate = self;
        _tabBarController.customizableViewControllers = nil;
        NSArray<UIViewController *> *vcs = _tabBarController.viewControllers;
        NSUInteger count = vcs.count;
        for (NSUInteger i = 0; i < count; ++i) {
            UIViewController *vc = vcs[i];
            if ([vc isKindOfClass:[LogWalkViewController class]]) {
                _tabBarController.selectedIndex = i;
                [self tabBarController:_tabBarController didSelectViewController:_tabBarController.selectedViewController];
                break;
            }
        }
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    UITabBarItem *item = tabBarController.tabBar.items[selectedIndex];
    
    // Kludge: showing and hiding the slider can affect the layout of the title label,
    // resulting in it being too narrow to fit. Reestablishing the titleView fixes that.
    self.navigationItem.titleView = nil;
    _titleLabel.text = item.title;
    self.navigationItem.titleView = _titleView;
}

- (IBAction)doShowSlider:(id)sender
{
    [[RootViewController sharedRootViewController] showSliderAndAlignTitleWithNavigationBarTitle:_titleLabel];
}

@end
