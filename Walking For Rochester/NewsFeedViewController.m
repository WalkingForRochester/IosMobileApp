//
//  NewsFeedViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import <WebKit/WebKit.h>
#import "NewsFeedViewController.h"

#import "HomeViewController.h"

#define kNewsFeedUrl @"https://walkingforrochester.org/category/news/"
#define kEmptyPageUrl @"about:blank"
#define kKeyEstimatedProgress @"estimatedProgress"

@interface NewsFeedViewController ()
{
    BOOL _usingBusyCount;
}

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation NewsFeedViewController

- (void)dealloc
{
    [_webView removeObserver:self forKeyPath:kKeyEstimatedProgress];
    if (_usingBusyCount)
        [HomeViewController sharedHomeViewController].busyCount -= 1;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_webView addObserver:self forKeyPath:kKeyEstimatedProgress options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kNewsFeedUrl]]];
    if (!_usingBusyCount) {
        _usingBusyCount = YES;
        [HomeViewController sharedHomeViewController].busyCount += 1;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kEmptyPageUrl]]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:kKeyEstimatedProgress]) {
        NSNumber *value = change[NSKeyValueChangeNewKey];
        if (_usingBusyCount && [value isKindOfClass:[NSNumber class]] && value.doubleValue >= 1) {
            _usingBusyCount = NO;
            [HomeViewController sharedHomeViewController].busyCount -= 1;
        }
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
