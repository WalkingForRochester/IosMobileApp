//
//  ProfileAccountTableViewCell.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import <UIKit/UIKit.h>

@protocol ProfileAccountTableViewCellDelegate;

@interface ProfileAccountTableViewCell : UITableViewCell

@property (weak, nonatomic) id<ProfileAccountTableViewCellDelegate> delegate;

@end

@protocol ProfileAccountTableViewCellDelegate

- (void)profileAccountTableViewCellDidDeleteAccount:(ProfileAccountTableViewCell *)profileAccountTableViewCell;
- (void)profileAccountTableViewCellDidLogout:(ProfileAccountTableViewCell *)profileAccountTableViewCell;

@end
