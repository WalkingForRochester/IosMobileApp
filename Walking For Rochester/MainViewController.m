//
//  MainViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/5/26.
//

#import <SafariServices/SafariServices.h>
#import "MainViewController.h"
#import "LoginViewController.h"
#import "ProfileRootViewController.h"
#import "Profile.h"
#import "APIManager.h"
#import "LogWalkViewController.h"
#import "SidebarTableViewCell.h"
#import "TouchForwardingTableView.h"
#import "ContactUsViewController.h"

typedef enum {
    kSidebarItemSafetyGuidelines = 0,
    kSidebarItemWaiver,
    kSidebarItemOurStory,
    kSidebarItemReportLitter,
    kSidebarItemAboutApp,
    kSidebarItemContactUs,
    kNumSideBarItems
} SidebarItemType;

static MainViewController __weak *s_sharedMainViewController;

@interface MainViewController () <UITabBarDelegate, UITableViewDelegate, UITableViewDataSource, TouchForwardingTableViewDelegate>
{
    UITabBarController __weak *_tabBarController;
    LogWalkViewController __weak *_logWalkViewController;
    CGPoint _touchPoint;
}

@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *startStopButtonView;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (weak, nonatomic) IBOutlet UITabBar *tabBar;
@property (weak, nonatomic) IBOutlet UITabBarItem *logWalkItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *leaderboardItem;
@property (weak, nonatomic) IBOutlet UITabBarItem *newsFeedItem;
@property (weak, nonatomic) IBOutlet UIView *sliderMaskView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet TouchForwardingTableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderViewRevealConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderViewWidthConstraint;

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
    
    _tabBar.selectedItem = _logWalkItem;
    [self tabBar:_tabBar didSelectItem:_logWalkItem];
    _sliderMaskView.alpha = 0;
    _sliderViewRevealConstraint.constant = 0;
    
    _tableView.panGestureRecognizer.cancelsTouchesInView = NO;
    
    _isSmallScreen = [UIScreen mainScreen].bounds.size.height <= 700;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _sliderViewWidthConstraint.constant = MIN(_sliderMaskView.bounds.size.width - 50, 400);
    _tableView.scrollEnabled = _tableView.contentSize.height > _tableView.frame.size.height;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (_sliderViewRevealConstraint.constant != 0) {
        WEAK_SELF_PTR;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            weakSelf.sliderViewRevealConstraint.constant = weakSelf.sliderView.bounds.size.width;
        } completion:nil];
    }
}

- (IBAction)doStartStop:(id)button
{
    if (!_logWalkViewController.walkInProgress)
        [_logWalkViewController startWalk];
    else
        [_logWalkViewController endWalk];
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    _titleLabel.text = item.title;
    _tabBarController.selectedIndex = item.tag;
    _startStopButtonView.hidden = item != _logWalkItem;
}

- (UIEdgeInsets)edgeInsetsForView:(UIView *)view
{
    return UIEdgeInsetsMake(0, 0, CGRectGetMaxY(view.bounds) - CGRectGetMinY([_tabBar convertRect:_tabBar.bounds toView:view]), 0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    WEAK_SELF_PTR;
    APIManager *manager = [APIManager sharedAPIManager];
    if (manager.accountId == nil)
        [self showLoginScreen];
    else [manager getUserProfileWithCompletion:^(APIManagerCall *call, Profile *profile, NSError *error) {
        if (error == nil && profile != nil && profile.accountId == nil) {
            manager.accountId = nil;
            [weakSelf showLoginScreen];
        }
        else
            ; // XXX
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
        _tabBarController.tabBar.hidden = YES;
        LogWalkViewController *vc = (LogWalkViewController *)_tabBarController.viewControllers[_logWalkItem.tag];
        if ([vc isKindOfClass:[LogWalkViewController class]])
            _logWalkViewController = vc;
    }
    else if ([target isKindOfClass:[ProfileRootViewController class]])
        self.navigationController.navigationBarHidden = NO;
}

- (IBAction)doShowSlider:(id)sender
{
    [self showSlider:YES];
}

- (IBAction)doHideSlider:(id)sender
{
    [self showSlider:NO];
}

- (void)showSlider:(BOOL)show
{
    WEAK_SELF_PTR;
    CGFloat reveal = show ? _sliderView.bounds.size.width : 0;
    CGFloat maskAlpha = show ? 1 : 0;
    NSTimeInterval duration = show ? 0.2 : 0.1;
    [UIView animateWithDuration:duration animations:^{
        weakSelf.sliderViewRevealConstraint.constant = reveal;
        weakSelf.sliderMaskView.alpha = maskAlpha;
        [weakSelf.view layoutIfNeeded];
    }];
}

- (BOOL)touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    return [view isDescendantOfView:_sliderView];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchForwardingTableView:_tableView forwardedTouchesBegan:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchForwardingTableView:_tableView forwardedTouchesMoved:touches withEvent:event];
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchForwardingTableView:_tableView forwardedTouchesEnded:touches withEvent:event];
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchForwardingTableView:_tableView forwardedTouchesCancelled:touches withEvent:event];
    [super touchesCancelled:touches withEvent:event];
}

- (BOOL)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    return YES;
}

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    _touchPoint = [touches.anyObject locationInView:_sliderMaskView];
}

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    CGPoint point = [touches.anyObject locationInView:_sliderMaskView];
    CGFloat delta = point.x - _touchPoint.x;
    if (delta <= 0) {
        CGFloat maxReveal = _sliderView.bounds.size.width;
        CGFloat reveal = maxReveal + delta;
        if (reveal != _sliderViewRevealConstraint.constant) {
            _sliderViewRevealConstraint.constant = reveal;
            [self.view layoutIfNeeded];
            _sliderMaskView.alpha = reveal / maxReveal;
        }
    }
    else
        _touchPoint = point;
}

- (void)maybeShowSliderAfterRelease
{
    [self showSlider:_sliderViewRevealConstraint.constant >= (_sliderView.bounds.size.width * 0.666)];
}

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    [self maybeShowSliderAfterRelease];
}

- (void)touchForwardingTableView:(TouchForwardingTableView *)touchForwardingTableView forwardedTouchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //NSLog(@"%@", NSStringFromSelector(_cmd));
    [self maybeShowSliderAfterRelease];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumSideBarItems;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SidebarTableViewCell *cell = (SidebarTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SidebarTableViewCell" forIndexPath:indexPath];
    NSString *imageName = nil;
    NSString *itemName = nil;
    switch ((SidebarItemType)indexPath.row) {
        case kSidebarItemSafetyGuidelines:
            imageName = @"image_health_and_safety";
            itemName = @"Safety Guidelines";
            break;
        case kSidebarItemWaiver:
            imageName = @"image_contract";
            itemName = @"Waiver";
            break;
        case kSidebarItemOurStory:
            imageName = @"image_article";
            itemName = @"Our Story";
            break;
        case kSidebarItemReportLitter:
            imageName = @"image_trash";
            itemName = @"Report Litter";
            break;
        case kSidebarItemAboutApp:
            imageName = @"image_info";
            itemName = @"About App";
            break;
        case kSidebarItemContactUs:
            imageName = @"image_help";
            itemName = @"Contact Us";
            break;
        case kNumSideBarItems:
            break;
    }
    
    [cell setImageName:imageName itemName:itemName];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ((SidebarItemType)indexPath.row) {
        case kSidebarItemSafetyGuidelines:
            [self showWebPage:@"https://docs.google.com/viewerng/viewer?embedded=true&url=https://walkingforrochester.com/pdf/guidelines.pdf"];
            break;
        case kSidebarItemWaiver:
            [self showWebPage:@"https://links.walkingforrochester.org/widget/form/LA27eLPPbgnxGtmJFZYK"];
            break;
        case kSidebarItemOurStory:
            [self showWebPage:@"https://walkingforrochester.org/our-story/"];
            break;
        case kSidebarItemReportLitter:
            [self showWebPage:@"https://walkingforrochester.org/report-litter/"];
            break;
        case kSidebarItemAboutApp:
            [self showWebPage:@"https://walkingforrochester.org/about-_the_app/"];
            break;
        case kSidebarItemContactUs:
            [self showContactUs];
            break;
        case kNumSideBarItems:
            break;
    }
}

- (void)showWebPage:(NSString *)urlString
{
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showContactUs
{
    ContactUsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactUsViewController"];
    [self.navigationController pushViewController:vc animated:YES];
    self.navigationController.navigationBarHidden = NO;
}

@end
