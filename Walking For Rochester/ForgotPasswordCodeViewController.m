//
//  ForgotPasswordCodeViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 4/29/26.
//

#import "ForgotPasswordCodeViewController.h"
#import "SignUpFieldView.h"
#import "ChangePasswordViewController.h"

@interface ForgotPasswordCodeViewController () <SignUpFieldViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet SignUpFieldView *codeField;

@end

@implementation ForgotPasswordCodeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _emailLabel.text = _email;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_codeField becomeFirstResponder];
}

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _codeField)
        return [_delegate forgotPasswordCodeViewController:self checkCode:signUpFieldView.text];
    NSAssert(NO, @"Field not handled");
    return NO;
}

- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (IBAction)doVerifyCode:(id)sender
{
    if ([_codeField validate]) {
        [_codeField resignFirstResponder];
        [self performSegueWithIdentifier:@"ChangePasswordViewControllerShowSegue" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *target = segue.destinationViewController;
    if ([target isKindOfClass:[ChangePasswordViewController class]]) {
        ChangePasswordViewController *vc = (ChangePasswordViewController *)target;
        vc.email = _email;
    }
}

@end
