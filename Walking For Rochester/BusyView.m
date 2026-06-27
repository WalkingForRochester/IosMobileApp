//
//  BusyView.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/6/26.
//

#import "BusyView.h"

@interface BusyView ()
{
    NSTimer *_maskTimer;
}

@property (weak, nonatomic) IBOutlet UIView *maskView;

@end

@implementation BusyView

+ (instancetype)addToView:(UIView *)parent
{
    BusyView *busyView = (BusyView *)[[NSBundle mainBundle] loadNibNamed:@"BusyView" owner:self options:nil][0];
    if ([busyView isKindOfClass:[BusyView class]]) {
        UIWindow *window = parent.window;
        [window addSubview:busyView];
        busyView.frame = window.bounds;
        return busyView;
    }
    return nil;
}

- (void)dealloc
{
    if (_maskTimer != nil)
        [_maskTimer invalidate];
}

- (void)setHidden:(BOOL)hidden
{
    BOOL isHidden = self.hidden;
    
    if (isHidden && !hidden && _maskTimer == nil) {
        _maskView.hidden = YES;
        _maskTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(maskTimerFired) userInfo:nil repeats:NO];
    }
    else if (!isHidden && hidden && _maskTimer != nil) {
        [_maskTimer invalidate];
        _maskTimer = nil;
    }
    [super setHidden:hidden];
}

- (void)maskTimerFired
{
    _maskTimer = nil;
    _maskView.hidden = NO;
}


@end
