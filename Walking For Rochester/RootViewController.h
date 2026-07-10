//
//  RootViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/15/26.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

- (void)popToViewControllerWithClass:(Class)class animated:(BOOL)animated;
- (void)showSliderAndAlignTitleWithNavigationBarTitle:(UILabel *)titleLabel;

@property (class, nonatomic, readonly) RootViewController *sharedRootViewController;

@end

