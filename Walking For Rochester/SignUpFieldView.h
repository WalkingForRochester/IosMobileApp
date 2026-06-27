//
//  SignUpFieldView.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 3/23/26.
//

#import <UIKit/UIKit.h>

@protocol SignUpFieldViewDelegate;

@interface SignUpFieldView : UIView

@property (weak, nonatomic) IBOutlet id<SignUpFieldViewDelegate> delegate;

- (BOOL)validate;
- (BOOL)validateAll;
- (void)clearError;
- (void)resignAll;
- (void)setErrorText:(NSString *)errorText isTemporary:(BOOL)isTemporary;

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)isFirstResponder;

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *errorText;

@end

@protocol SignUpFieldViewDelegate

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text;
- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;

@end
