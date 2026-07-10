//
//  WaitToken.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 7/9/26.
//

#import "WaitToken.h"
#import "BusyView.h"
#import "RootViewController.h"

static BusyView __weak *s_busyView;
static NSInteger s_busyCount;
static BOOL s_busyViewUpdatePending;

@interface WaitToken ()

@property (class, nonatomic) NSInteger busyCount;

@end

@implementation WaitToken

- (void)dealloc
{
    NSAssert(s_busyCount >= 1, @"Expected a count >= 0");
    self.class.busyCount -= 1;
}

- (id)init
{
    if ((self = [super init]) != nil)
        self.class.busyCount += 1;
    return self;
}

+ (NSInteger)busyCount
{
    return s_busyCount;
}

+ (void)setBusyCount:(NSInteger)busyCount
{
    if (busyCount != s_busyCount || s_busyView == nil) {
        BOOL isHidden = busyCount <= 0;
        BOOL wasHidden = s_busyCount <= 0 || s_busyView == nil;
        s_busyCount = busyCount;
        if (isHidden != wasHidden && !s_busyViewUpdatePending) {
            s_busyViewUpdatePending = YES;
            WEAK_SELF_PTR;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateBusyView];
            });
        }
    }
}

+ (void)updateBusyView
{
    s_busyViewUpdatePending = NO;
    BOOL shouldBeHidden = s_busyCount <= 0;
    BOOL isHidden = s_busyView == nil || s_busyView.hidden;
    if (shouldBeHidden && !isHidden)
        s_busyView.hidden = YES;
    else if (!shouldBeHidden && isHidden) {
        if (s_busyView == nil) {
            UIView *view = [RootViewController sharedRootViewController].view;
            if (view != nil)
                s_busyView = [BusyView addToView:view];
        }
        else {
            s_busyView.hidden = NO;
            [s_busyView.superview bringSubviewToFront:s_busyView];
        }
    }
}

@end
