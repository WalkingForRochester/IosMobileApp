//
//  CustomBarButtonItem.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/20/26.
//

#import "CustomBarButtonItem.h"

@implementation CustomBarButtonItem

@dynamic customViewForInterfaceBuilder;

- (void)setCustomViewForInterfaceBuilder:(UIView *)customViewForInterfaceBuilder
{
    self.customView = customViewForInterfaceBuilder;
}

- (UIView *)customViewForInterfaceBuilder
{
    return self.customView;
}

- (void)setHidesSharedBackground:(BOOL)hidesSharedBackground
{
    if (@available(iOS 26.0, *)) {
        [super setHidesSharedBackground:hidesSharedBackground];
    }
}

@end
