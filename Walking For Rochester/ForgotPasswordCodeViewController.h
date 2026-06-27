//
//  ForgotPasswordCodeViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 4/29/26.
//

#import <UIKit/UIKit.h>

@protocol ForgotPasswordCodeViewControllerDelegate;

@interface ForgotPasswordCodeViewController : UIViewController

@property (weak, nonatomic) id<ForgotPasswordCodeViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString *email;

@end

@protocol ForgotPasswordCodeViewControllerDelegate

- (BOOL)forgotPasswordCodeViewController:(ForgotPasswordCodeViewController *)forgotPasswordCodeViewController checkCode:(NSString *)code;

@end
