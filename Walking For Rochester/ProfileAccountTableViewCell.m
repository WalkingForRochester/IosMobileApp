//
//  ProfileAccountTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import "ProfileAccountTableViewCell.h"

@implementation ProfileAccountTableViewCell

- (IBAction)doDeleteAccount:(id)sender
{
    [_delegate profileAccountTableViewCellDidDeleteAccount:self];
}

- (IBAction)doLogout:(id)sender
{
    [_delegate profileAccountTableViewCellDidLogout:self];
}

@end
