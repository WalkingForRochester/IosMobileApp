//
//  KeyboardFixViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 7/2/26.
//

#import "KeyboardFixViewController.h"

@interface KeyboardFixViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation KeyboardFixViewController

- (void)dealloc
{
    // This can be called whether or not the fix is active.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(_scrollView != nil, @"Expected scrollView");
    NSAssert(_keyboardLayoutConstraint != nil, @"Expected keyboardLayoutConstraint");
    if (!@available(iOS 16.0, *)) {
        _keyboardLayoutConstraint.active = NO;
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(handleiOS15Keyboard:) name:UIKeyboardWillShowNotification object:nil];
        [center addObserver:self selector:@selector(handleiOS15Keyboard:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)handleiOS15Keyboard:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat adjustedHeight = keyboardFrame.size.height - self.view.safeAreaInsets.bottom;
    BOOL isShow = [notification.name isEqualToString:UIKeyboardWillShowNotification];
    UIEdgeInsets insets = isShow ? UIEdgeInsetsMake(0, 0, adjustedHeight, 0) : UIEdgeInsetsZero;
    
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIScrollView __weak *scrollView = _scrollView;
    [UIView animateWithDuration:duration animations:^{
        scrollView.contentInset = insets;
        scrollView.scrollIndicatorInsets = insets;
    }];
}

@end
