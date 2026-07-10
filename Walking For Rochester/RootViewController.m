//
//  RootViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/15/26.
//

#import <SafariServices/SafariServices.h>
#import "RootViewController.h"
#import "TouchForwardingTableView.h"
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

static RootViewController __weak *s_sharedRootViewController;

@interface RootViewController () <UITableViewDelegate, UITableViewDataSource, TouchForwardingTableViewDelegate>
{
    UINavigationController *_navigationController;
    CGPoint _touchPoint;
}

@property (weak, nonatomic) IBOutlet UIView *sliderMaskView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *sliderTitleLabel;
@property (weak, nonatomic) IBOutlet TouchForwardingTableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderTitleLabelTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderViewRevealConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderViewWidthConstraint;

@end

@implementation RootViewController

+ (RootViewController *)sharedRootViewController
{
    return s_sharedRootViewController;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]) != nil)
        s_sharedRootViewController = self;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
         
    _sliderMaskView.alpha = 0;
    _sliderViewRevealConstraint.constant = 0;
    
    _tableView.panGestureRecognizer.cancelsTouchesInView = NO;
    _sliderView.layer.maskedCorners = kCALayerMaxXMinYCorner | kCALayerMaxXMaxYCorner;
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

- (void)showSliderAndAlignTitleWithNavigationBarTitle:(UILabel *)titleLabel
{
    _sliderTitleLabel.font = titleLabel.font;
    _sliderTitleLabel.textColor = titleLabel.textColor;
    NSLayoutConstraint *alignConstraint = [_sliderTitleLabel.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor];
    _sliderTitleLabelTopConstraint.active = NO;
    alignConstraint.active = YES;
    [self.view layoutIfNeeded];
    [self showSlider:YES];
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

- (IBAction)doHideSlider:(id)sender
{
    [self showSlider:NO];
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
    [self showSlider:NO];
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)showContactUs
{
    ContactUsViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ContactUsViewController"];
    [self showSlider:NO];
    [_navigationController pushViewController:vc animated:YES];
}

@end
