//
//  HomeViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/15/26.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController

- (void)popToViewControllerWithClass:(Class)class animated:(BOOL)animated;

@property (class, nonatomic, readonly) HomeViewController *sharedHomeViewController;
@property (assign, nonatomic) NSInteger busyCount;

@end

