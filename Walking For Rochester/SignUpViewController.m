//
//  SignUpViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/19/26.
//

#import "SignUpViewController.h"
#import "SignUpFieldView.h"
#import "APIManager.h"
#import "RootViewController.h"
#import "MainViewController.h"
#import "NSString+Extensions.h"

#define kMinNameLength 1

@interface SignUpViewController () <SignUpFieldViewDelegate>

@property (weak, nonatomic) IBOutlet SignUpFieldView *firstNameView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *lastNameView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *emailView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *displayNameView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *passwordView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *confirmPasswordView;
@property (weak, nonatomic) IBOutlet UISwitch *communityServiceSwitch;

@end

@implementation SignUpViewController

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _firstNameView || signUpFieldView == _lastNameView)
        return text.length >= kMinNameLength;
    else if (signUpFieldView == _emailView)
        return [text isValidEmailAddress];
    else if (signUpFieldView == _displayNameView)
        return YES;
    else if (signUpFieldView == _passwordView)
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

- (IBAction)doSignUp:(id)sender
{
    if ([_firstNameView validateAll]) {
        [_firstNameView resignAll];
        WEAK_SELF_PTR;
        NSString *firstName = _firstNameView.text;
        NSString *lastName = _lastNameView.text;
        NSString *email = _emailView.text;
        NSString *displayName = _displayNameView.text;
        NSString *password = _passwordView.text;
        BOOL isCommunityService = _communityServiceSwitch.on;
        APIManager *manager = [APIManager sharedAPIManager];
        [manager accountByEmail:email completion:^(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error) {
            if (error == nil && (accountId != nil || errorText.length != 0)) {
                if (accountId != nil)
                    [weakSelf duplicateAccount];
                else if (errorText.length != 0) {
                    [manager signUpWithFirstName:firstName lastName:lastName email:email displayName:displayName password:password isCommunityService:isCommunityService completion:^(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error) {
                        if (error == nil && accountId != nil)
                            [[RootViewController sharedRootViewController] popToViewControllerWithClass:[MainViewController class] animated:YES];
                        else
                            [call showErrorForViewController:self];
                    }];
                }
            }
            else
                [call showErrorForViewController:self];
        }];
    }
}

- (void)duplicateAccount
{
    [_emailView setErrorText:@"Email already registered" isTemporary:YES];
}

@end
