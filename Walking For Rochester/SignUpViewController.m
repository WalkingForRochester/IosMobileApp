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
@property (weak, nonatomic) IBOutlet SignUpFieldView *phoneView;
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
    else if (signUpFieldView == _phoneView)
        return [text decimalDigits].length == 10;
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
    if (signUpFieldView == _phoneView) {
        NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        textField.text = [text tenDigitFormattedPhoneNumber];
        UITextPosition *end = textField.endOfDocument;
        textField.selectedTextRange = [textField textRangeFromPosition:end toPosition:end];
        [_phoneView clearError];
        return NO;
    }
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
        NSString *phone = [_phoneView.text decimalDigits];
        NSString *displayName = _displayNameView.text;
        NSString *password = _passwordView.text;
        BOOL isCommunityService = _communityServiceSwitch.on;
        APIManager *manager = [APIManager sharedAPIManager];
        [manager accountByEmail:email completion:^(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error) {
            if (accountId != nil)
                [weakSelf duplicateAccount];
            else if (errorText.length != 0) {
                [manager signUpWithFirstName:firstName lastName:lastName email:email phone:phone displayName:displayName password:password isCommunityService:isCommunityService completion:^(APIManagerCall *call, APIManagerAccountID *accountId, NSString *errorText, NSError *error) {
                    [[RootViewController sharedRootViewController] popToViewControllerWithClass:[MainViewController class] animated:YES];
                }];
            }
        }];
    }
}

- (void)duplicateAccount
{
    [_emailView setErrorText:@"Email already registered" isTemporary:YES];
}

@end
