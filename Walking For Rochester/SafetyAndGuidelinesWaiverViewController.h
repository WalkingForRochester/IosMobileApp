//
//  SafetyAndGuidelinesWaiverViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/6/26.
//

#import <UIKit/UIKit.h>

@protocol SafetyAndGuidelinesWaiverViewControllerDelegate;

@interface SafetyAndGuidelinesWaiverViewController : UIViewController

@property (weak, nonatomic) id<SafetyAndGuidelinesWaiverViewControllerDelegate> delegate;

@end

@protocol SafetyAndGuidelinesWaiverViewControllerDelegate

- (void)safetyAndGuidelinesWaiverViewController:(SafetyAndGuidelinesWaiverViewController *)vc didCloseAndAcceptWaiver:(BOOL)accept;

@end
