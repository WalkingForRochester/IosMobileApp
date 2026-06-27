//
//  SafetyAndGuidelinesWaiverViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/6/26.
//

#import <SafariServices/SafariServices.h>
#import "SafetyAndGuidelinesWaiverViewController.h"

#define kGuidelinesUrl @"https://docs.google.com/viewerng/viewer?embedded=true&url=https://walkingforrochester.com/pdf/guidelines.pdf"
#define kWaiverUrl @"https://links.walkingforrochester.org/widget/form/LA27eLPPbgnxGtmJFZYK"

@interface SafetyAndGuidelinesWaiverViewController ()

@end

@implementation SafetyAndGuidelinesWaiverViewController

- (IBAction)doAccept:(id)sender
{
    [_delegate safetyAndGuidelinesWaiverViewController:self didCloseAndAcceptWaiver:YES];
}

- (IBAction)doDecline:(id)sender
{
    [_delegate safetyAndGuidelinesWaiverViewController:self didCloseAndAcceptWaiver:NO];
}

- (IBAction)doViewSafetyGuidelines:(id)sender
{
    [self showWebBrowserWithUrlString:kGuidelinesUrl];
}

- (IBAction)doViewWaiver:(id)sender
{
    [self showWebBrowserWithUrlString:kWaiverUrl];
}

- (void)showWebBrowserWithUrlString:(NSString *)urlStr
{
    NSURL *url = [NSURL URLWithString:urlStr];
    
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
    
    vc.preferredBarTintColor = [UIColor systemBackgroundColor];
    vc.preferredControlTintColor = [UIColor systemBlueColor];
    
    [self presentViewController:vc animated:YES completion:nil];
}

@end
