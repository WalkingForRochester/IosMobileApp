//
//  FinishWalkViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/15/26.
//

#import <UIKit/UIKit.h>

@class Walk;
@protocol FinishWalkViewControllerDelegate;

@interface FinishWalkViewController : UIViewController

@property (weak, nonatomic) id<FinishWalkViewControllerDelegate> delegate;
@property (strong, nonatomic) Walk *walk;

@end

@protocol FinishWalkViewControllerDelegate

- (void)finishWalkViewControllerDidDiscardWalk:(FinishWalkViewController *)finishWalkViewController;

- (void)finishWalkViewControllerDidUploadWalk:(FinishWalkViewController *)finishWalkViewController;

@end
