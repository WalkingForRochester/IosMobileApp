//
//  ProfileUserTableViewCell.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import <UIKit/UIKit.h>

@class Profile;
@class ProfileViewController;

@interface ProfileUserTableViewCell : UITableViewCell

@property (strong, nonatomic) Profile *profile;
@property (weak, nonatomic) ProfileViewController *profileViewController;

@end
