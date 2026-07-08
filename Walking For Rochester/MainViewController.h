//
//  MainViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/5/26.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController

@property (class, nonatomic, readonly) MainViewController *sharedMainViewController;
@property (assign, nonatomic, readonly) BOOL isSmallScreen;

@end
