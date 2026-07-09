//
//  ProfileViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/12/26.
//

#import <UIKit/UIKit.h>

@class Profile;

@interface ProfileViewController : UIViewController

- (void)refresh;

@property (strong, nonatomic, readonly) Profile *profile;

@end
