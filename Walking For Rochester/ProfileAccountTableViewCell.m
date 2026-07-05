//
//  ProfileAccountTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import "ProfileAccountTableViewCell.h"
#import "MainViewController.h"

@interface ProfileAccountTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonVerticalSpacingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonBottomSpacingConstraint;

@end

@implementation ProfileAccountTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([MainViewController sharedMainViewController].isSmallScreen) {
        _buttonVerticalSpacingConstraint.constant /= 2;
        _buttonBottomSpacingConstraint.constant /= 2;
    }
}

- (IBAction)doDeleteAccount:(id)sender
{
    [_delegate profileAccountTableViewCellDidDeleteAccount:self];
}

- (IBAction)doLogout:(id)sender
{
    [_delegate profileAccountTableViewCellDidLogout:self];
}

@end
