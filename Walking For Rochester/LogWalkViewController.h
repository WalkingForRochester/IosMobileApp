//
//  LogWalkViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import <UIKit/UIKit.h>

#define kLogWalkViewControllerWalkInProgressKeyPath @"walkInProgress"

@interface LogWalkViewController : UIViewController

+ (void)launchSettingsApp;

- (void)startWalk;
- (void)endWalk;

@property (assign, nonatomic, readonly) BOOL walkInProgress;

@end
