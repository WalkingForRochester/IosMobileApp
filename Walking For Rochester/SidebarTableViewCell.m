//
//  SidebarTableViewCell.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/25/26.
//

#import "SidebarTableViewCell.h"

@interface SidebarTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation SidebarTableViewCell

- (void)setImageName:(NSString *)imageName itemName:(NSString *)itemName
{
    _iconImageView.image = [UIImage imageNamed:imageName];
    _nameLabel.text = itemName;
}

@end
