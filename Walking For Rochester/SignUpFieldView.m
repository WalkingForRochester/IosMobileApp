//
//  SignUpFieldView.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/23/26.
//

#import "SignUpFieldView.h"

@interface SignUpFieldView () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet SignUpFieldView *next;

@end

@implementation SignUpFieldView

@dynamic text;

- (void)awakeFromNib
{
    [super awakeFromNib];
    _errorText = _errorLabel.text;
    _errorLabel.text = nil;
    _textField.returnKeyType = _next != nil ? UIReturnKeyNext : UIReturnKeyDone;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (_next != nil)
        [_next.textField becomeFirstResponder];
    else
        [textField resignFirstResponder];
    return NO;
}

 - (void)clearError
{
    _errorLabel.text = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL change = [_delegate signUpFieldView:self textField:textField shouldChangeCharactersInRange:range replacementString:string];
    if (change)
        [self clearError];
    return change;
}

- (void)setText:(NSString *)text
{
    _textField.text = text;
}

- (NSString *)text
{
    return [_textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)setErrorText:(NSString *)errorText
{
    [self setErrorText:errorText isTemporary:NO];
}

- (void)setErrorText:(NSString *)errorText isTemporary:(BOOL)isTemporary
{
    if (!isTemporary)
        _errorText = errorText;
    _errorLabel.text = errorText;
}

- (BOOL)validate
{
    BOOL valid = YES;
    if (_delegate != nil) {
        valid = [_delegate signUpFieldViewIsContentValid:self text:self.text];
        _errorLabel.text = valid ? nil : _errorText;
    }
    return valid;
}

- (BOOL)validateAll
{
    BOOL isValid = YES;
    for (SignUpFieldView *field = self; field != nil; field = field.next)
        isValid &= [field validate];
    return isValid;
}

- (void)resignAll
{
    for (SignUpFieldView *field = self; field != nil; field = field.next)
        if (self.isFirstResponder) {
            [self resignFirstResponder];
            break;
        }
}

- (BOOL)becomeFirstResponder
{
    return [_textField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [_textField resignFirstResponder];
}

- (BOOL)isFirstResponder
{
    return [_textField isFirstResponder];
}

@end
