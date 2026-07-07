//
//  SpoofDetectedViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 7/7/26.
//

#import "SpoofDetectedViewController.h"

@interface SpoofDetectedViewController ()

@end

@implementation SpoofDetectedViewController

- (IBAction)doUnderstood:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
