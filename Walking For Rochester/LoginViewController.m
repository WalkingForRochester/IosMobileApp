//
//  LoginViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 1/16/26.
//

#import "LoginViewController.h"
#import "SignUpFieldView.h"
#import "APIManager.h"
#import "NSString+Extensions.h"

@interface LoginViewController () <SignUpFieldViewDelegate>

@property (weak, nonatomic) IBOutlet SignUpFieldView *emailView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *passwordView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIStackView *stackView;

@end

@implementation LoginViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _emailView)
        return [text isValidEmailAddress];
    else if (signUpFieldView == _passwordView)
        return YES;
    NSAssert(NO, @"Field not handled");
    return NO;
}

- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (IBAction)doSignIn:(id)sender
{
    if ([_emailView validateAll]) {
        [_emailView resignAll];
        WEAK_SELF_PTR;
        [[APIManager sharedAPIManager] signInWithEmail:_emailView.text password:_passwordView.text completion:^(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error) {
            if (accountId != nil) {
                weakSelf.passwordView.errorText = nil;
                NSLog(@"logged in with error %@, accountId %@", error, accountId);
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }
            else if (errorText.length != 0)
                weakSelf.passwordView.errorText = errorText;
        }];
    }
}

@end
