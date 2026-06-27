//
//  ContactUsViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/26/26.
//

#import "ContactUsViewController.h"
#import "NSString+Extensions.h"

@interface ContactUsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation ContactUsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSInteger buildNumber = [[bundle objectForInfoDictionaryKey:(__bridge id)kCFBundleVersionKey] integerValue];
    NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    _versionLabel.text = [NSString stringWithFormat:@"%@ %@ (build %@)", _versionLabel.text, version, @(buildNumber)];
}

- (IBAction)doPhone:(UIButton *)button
{
    NSString *digits = [button.titleLabel.attributedText.string decimalDigits];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", digits]];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (IBAction)doEmail:(UIButton *)button
{
    NSString *email = button.titleLabel.attributedText.string;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", email]];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end
