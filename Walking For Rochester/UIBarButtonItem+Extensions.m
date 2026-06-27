//
//  UIBarButtonItem+Extensions.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/20/26.
//

#import "UIBarButtonItem+Extensions.h"

@implementation UIBarButtonItem (Extensions)

@dynamic customViewForInterfaceBuilder;

- (void)setCustomViewForInterfaceBuilder:(UIView *)customViewForInterfaceBuilder
{
    self.customView = customViewForInterfaceBuilder;
}

- (UIView *)customViewForInterfaceBuilder
{
    return self.customView;
}

@end
