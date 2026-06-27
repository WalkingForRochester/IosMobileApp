//
//  HomeViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/15/26.
//

#import "HomeViewController.h"
#import "BusyView.h"

static HomeViewController __weak *s_sharedHomeViewController;

@interface HomeViewController ()
{
    UINavigationController *_navigationController;
    BusyView __weak *_busyView;
    NSInteger _busyCount;
    BOOL _waitViewUpdatePending;
}

@end

@implementation HomeViewController

+ (HomeViewController *)sharedHomeViewController
{
    return s_sharedHomeViewController;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]) != nil)
        s_sharedHomeViewController = self;
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (_busyView == nil) {
        _busyView = [BusyView addToView:self.view];
        _busyView.hidden = YES;
    }
}

- (NSInteger)busyCount
{
    return _busyCount;
}

- (void)setBusyCount:(NSInteger)busyCount
{
    if (busyCount != _busyCount) {
        BOOL isHidden = busyCount <= 0;
        BOOL wasHidden = _busyCount <= 0;
        _busyCount = busyCount;
        if (isHidden != wasHidden && !_waitViewUpdatePending) {
            _waitViewUpdatePending = YES;
            WEAK_SELF_PTR;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateWaitView];
            });
        }
    }
}

- (void)updateWaitView
{
    _waitViewUpdatePending = NO;
    BOOL shouldBeHidden = _busyCount <= 0;
    BOOL isHidden = _busyView.hidden;
    if (shouldBeHidden && !isHidden)
        _busyView.hidden = YES;
    else if (!shouldBeHidden && isHidden) {
        _busyView.hidden = NO;
        [_busyView.superview bringSubviewToFront:_busyView];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *target = segue.destinationViewController;
    if ([target isKindOfClass:[UINavigationController class]])
        _navigationController = (UINavigationController *)target;
}

- (void)popToViewControllerWithClass:(Class)class animated:(BOOL)animated
{
    for (UIViewController *vc in _navigationController.viewControllers.reverseObjectEnumerator)
        if ([vc isKindOfClass:class]) {
            [_navigationController popToViewController:vc animated:animated];
            break;
        }
}

@end
