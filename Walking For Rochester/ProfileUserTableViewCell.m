//
//  ProfileUserTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import "ProfileUserTableViewCell.h"
#import "Profile.h"
#import "ProfileViewController.h"
#import "ProfileStatisticsTableViewCell.h"
#import "ImageLoader.h"
#import "RoundImageView.h"
#import "NSString+Extensions.h"

@interface ProfileUserTableViewCell ()
{
    ImageLoader *_imageLoader;
}

@property (weak, nonatomic) IBOutlet RoundImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UILabel *profileLabel;

@end

@implementation ProfileUserTableViewCell

- (void)setProfile:(Profile *)profile
{
    _profile = profile;
    NSURL *imageUrl = profile.imgUrl;
    if (imageUrl != nil) {
        WEAK_SELF_PTR;
        _imageLoader = [ImageLoader new];
        [_imageLoader loadImageAtURL:imageUrl completion:^(UIImage *image) {
            if ([imageUrl isEqual:weakSelf.profile.imgUrl])
                weakSelf.profileImageView.image = image;
        }];
    }
    NSMutableString *text = [NSMutableString stringWithCapacity:1024];
    APIManagerAccountID *accountId = profile.accountId;
    if (accountId != nil)
        [text appendFormat:@"AccountID: %@\n", accountId];
    NSString *nickname = profile.nickname;
    if (nickname.length != 0)
        [text appendFormat:@"%@\n", nickname];
    NSString *email = profile.email;
    if (email.length != 0)
        [text appendFormat:@"%@\n", email];
    NSString *phone = [profile.phoneNumber tenDigitFormattedPhoneNumber];
    if (phone.length != 0)
        [text appendFormat:@"%@\n", phone];
    if (text.length != 0)
        [text appendFormat:@"Community service: %@", profile.communityService ? @"YES" : @"NO"];
    _profileLabel.text = text;
}

- (IBAction)doShare:(id)sender
{
    NSString *message = [NSString stringWithFormat:@"\
Check out my stats with Walking For Rochester!\n\
Distance, last walk: %@. overall: %@\n\
Duration, last walk: %@. overall: %@\
",
                         [ProfileStatisticsTableViewCell formatDistanceInMeters:_profile.distance],
                         [ProfileStatisticsTableViewCell formatDistanceInMeters:_profile.totalDistance],
                         [ProfileStatisticsTableViewCell formatDurationInMilliseconds:_profile.duration],
                         [ProfileStatisticsTableViewCell formatDurationInMilliseconds:_profile.totalDuration]
    ];
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[ message ] applicationActivities:nil];
    [_profileViewController presentViewController:vc animated:YES completion:nil];
}

@end
