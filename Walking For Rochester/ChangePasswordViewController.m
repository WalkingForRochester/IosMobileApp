//
//  ChangePasswordViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 4/30/26.
//

#import "ChangePasswordViewController.h"
#import "SignUpFieldView.h"
#import "APIManager.h"
#import "HomeViewController.h"
#import "LoginViewController.h"
#import "NSString+Extensions.h"

@interface ChangePasswordViewController () <SignUpFieldViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet SignUpFieldView *passwordView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *confirmPasswordView;

@end

@implementation ChangePasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _emailLabel.text = _email;
}

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _passwordView)
        return text.length >= kAPIManagerMinPasswordLength;
    else if (signUpFieldView == _confirmPasswordView)
        return [text isEqualToString:_passwordView.text];
    NSAssert(NO, @"Field not handled");
    return NO;
}


- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (IBAction)doChangePassword:(id)sender
{
    if ([_passwordView validateAll]) {
        [_passwordView resignAll];
        [[APIManager sharedAPIManager] resetPasswordWithEmail:_email password:_passwordView.text completion:^(APIManagerCall *call, BOOL succeeded, NSError *error) {
            if (succeeded)
                [[HomeViewController sharedHomeViewController] popToViewControllerWithClass:[LoginViewController class] animated:YES];
        }];
    }
}


@end
