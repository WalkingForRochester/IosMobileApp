//
//  MainViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/5/26.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

- (UIEdgeInsets)edgeInsetsForView:(UIView *)view;

@property (class, nonatomic, readonly) MainViewController *sharedMainViewController;

@end
