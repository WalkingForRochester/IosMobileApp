//
//  ForgotPasswordRootViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/5/26.
//

#import "ForgotPasswordRootViewController.h"

@interface ForgotPasswordRootViewController ()

@end

@implementation ForgotPasswordRootViewController

// Note: the view controllers in the forgot password sequence have their own navigation controller, which is embedded in this view controller.
// The reason for this is two-fold:
// 1. Since the navigation bar is that of the navigaion controller on which this view controller resides and the embedded navigation controller
// does not display a navigation bar, moving between the view controllers in the fogot password sequence does not trigger animations in the navigation bar.
// This is needed, since they all have the same title.
// 2. We are mimicking behavior in the Android app where, tapping the back button from any view controller in the sequence always goes back to the main login
// screen, i.e. the user can't go back to previouos screens in the forgot password seequence. This is by design.

@end
