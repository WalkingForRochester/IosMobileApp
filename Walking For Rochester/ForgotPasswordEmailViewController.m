//
//  ForgotPasswordEmailViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/21/26.
//

#import "ForgotPasswordEmailViewController.h"
#import "SignUpFieldView.h"
#import "ForgotPasswordCodeViewController.h"
#import "APIManager.h"
#import "NSString+Extensions.h"

@interface ForgotPasswordEmailViewController () <SignUpFieldViewDelegate, ForgotPasswordCodeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet SignUpFieldView *emailView;
@property (weak, nonatomic) NSString *code;

@end

@implementation ForgotPasswordEmailViewController

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _emailView)
        return [text isValidEmailAddress];
    NSAssert(NO, @"Field not handled");
    return NO;
}

- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (IBAction)doRequestCode:(id)sender
{
    if ([_emailView validateAll]) {
        [_emailView resignAll];
        WEAK_SELF_PTR;
        NSString *email = _emailView.text;
        [[APIManager sharedAPIManager] forgotPasswordWithEmail:email completion:^(APIManagerCall *call, NSString *code, NSError *error) {
            if (error == nil && code.length != 0) {
                weakSelf.code = code;
                [weakSelf performSegueWithIdentifier:@"ForgotPasswordCodeViewControllerShowSegue" sender:self];
            }
            else
                [call showErrorForViewController:self];
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *target = segue.destinationViewController;
    if ([target isKindOfClass:[ForgotPasswordCodeViewController class]]) {
        ForgotPasswordCodeViewController *vc = (ForgotPasswordCodeViewController *)target;
        vc.delegate = self;
        vc.email = _emailView.text;
    }
}

- (BOOL)forgotPasswordCodeViewController:(ForgotPasswordCodeViewController *)forgotPasswordCodeViewController checkCode:(NSString *)code
{
    return [self.code isEqualToString:code];
}

@end
