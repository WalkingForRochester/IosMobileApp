//
//  WaitToken.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 7/9/26.
//

#import "WaitToken.h"
#import "RootViewController.h"

@implementation WaitToken

- (void)dealloc
{
    [RootViewController sharedRootViewController].busyCount -= 1;
}

- (id)init
{
    if ((self = [super init]) != nil)
        [RootViewController sharedRootViewController].busyCount += 1;
    return self;
}

@end
