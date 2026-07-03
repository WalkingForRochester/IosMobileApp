//
//  CALayer+Extensions.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/15/26.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "CALayer+Extensions.h"

@implementation CALayer (BorderCustom)

- (void)custom_setBorderColor:(CGColorRef)color
{
    [self custom_setBorderColor:color];
}

@end

@implementation CALayer (Extensions)

+ (void)load
{
    [self swapOriginalSelector:@selector(setBorderColor:) swizzledSelector:@selector(custom_setBorderColor:)];
    [self swapOriginalSelector:@selector(setShadowColor:) swizzledSelector:@selector(custom_setShadowColor:)];
}

+ (void)swapOriginalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector
{
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod = class_addMethod(class, originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod)
        class_replaceMethod(class, swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    else
        method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)custom_setBorderColor:(CGColorRef)borderColor
{
    if ([(__bridge id)borderColor isKindOfClass:[UIColor class]])
        borderColor = ((UIColor *)(__bridge id)borderColor).CGColor;
    [self custom_setBorderColor:borderColor];
}

- (void)custom_setShadowColor:(CGColorRef)shadowColor
{
    if ([(__bridge id)shadowColor isKindOfClass:[UIColor class]])
        shadowColor = ((UIColor *)(__bridge id)shadowColor).CGColor;
    [self custom_setShadowColor:shadowColor];
}

@end
