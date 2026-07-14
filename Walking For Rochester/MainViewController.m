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
    LogWalkViewController __weak *_logWalkViewController;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *startStopButtonView;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *startStopButtonViewBottomConstraint;

@end

@implementation MainViewController

+ (MainViewController *)sharedMainViewController
{
    return s_sharedMainViewController;
}

- (void)dealloc
{
    [_logWalkViewController removeObserver:self forKeyPath:kLogWalkViewControllerWalkInProgressKeyPath];
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
        
    // Interface Builder doesn't allow setting the button to have multiple states
    // as well as having the icon be on top. As a compromise, the image, title, font,
    // and background color are set in interface builder and then we use the code below
    // to switch to a button that allows a top icon with padding. The rest of the code is
    // needed to handle the font and the state switching.
    UIFont *font = _startStopButton.titleLabel.font;
    UIColor *color = _startStopButton.backgroundColor;
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.imagePlacement = NSDirectionalRectEdgeTop;
    config.imagePadding = 4;
    config.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> * (NSDictionary<NSAttributedStringKey,id> *attributes) {
            NSMutableDictionary *mAttributes = [attributes mutableCopy];
            mAttributes[NSFontAttributeName] = font;
            return mAttributes;
        };
    _startStopButton.configuration = config;
    _startStopButton.configurationUpdateHandler = ^(UIButton *button) {
        UIButtonConfiguration *currentConfig = button.configuration;
        UIControlState currentState = button.state;
        currentConfig.title = [button titleForState:currentState];
        currentConfig.image = [button imageForState:currentState];
        currentConfig.baseBackgroundColor = color;
        button.configuration = currentConfig;
    };
    
    _isSmallScreen = [UIScreen mainScreen].bounds.size.height <= 700;
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (_tabBarController != nil) {
        UITabBar *tabBar = _tabBarController.tabBar;
        UIView *view = _startStopButtonView.superview;
        CGRect tabBarFrame = [tabBar convertRect:tabBar.bounds toView:view];
        _startStopButtonViewBottomConstraint.constant = 10 + view.bounds.size.height - tabBarFrame.origin.y;
    }
}

- (IBAction)doStartStop:(id)button
{
    if (!_logWalkViewController.walkInProgress)
        [_logWalkViewController startWalk];
    else
        [_logWalkViewController endWalk];
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
    NSAssert(_logWalkViewController != nil, @"Can't find log walk view controller");
    [_logWalkViewController addObserver:self forKeyPath:kLogWalkViewControllerWalkInProgressKeyPath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object == _logWalkViewController && [keyPath isEqualToString:kLogWalkViewControllerWalkInProgressKeyPath])
        _startStopButton.selected = _logWalkViewController.walkInProgress;
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
                _logWalkViewController = (LogWalkViewController *)vc;
                _tabBarController.selectedIndex = i;
                [self tabBarController:_tabBarController didSelectViewController:_tabBarController.selectedViewController];
                break;
            }
        }
        NSAssert(_logWalkViewController != nil, @"Can't fit log walk tab");
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSUInteger selectedIndex = tabBarController.selectedIndex;
    UITabBarItem *item = tabBarController.tabBar.items[selectedIndex];
    _startStopButtonView.hidden = viewController != _logWalkViewController;
    _titleLabel.text = item.title;
    [self.view setNeedsLayout];
}

- (IBAction)doShowSlider:(id)sender
{
    [[RootViewController sharedRootViewController] showSliderAndAlignTitleWithNavigationBarTitle:_titleLabel];
}

@end
