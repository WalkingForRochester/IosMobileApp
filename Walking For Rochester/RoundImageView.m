//
//  RoundImageView.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import "RoundImageView.h"

@implementation RoundImageView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2;
}

@end
