//
//  NewsFeedViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import <WebKit/WebKit.h>
#import "NewsFeedViewController.h"
#import "WaitToken.h"

#define kNewsFeedUrl @"https://walkingforrochester.org/category/news/"
#define kEmptyPageUrl @"about:blank"
#define kKeyEstimatedProgress @"estimatedProgress"

@interface NewsFeedViewController ()
{
    WaitToken *_waitToken;
}

@property (weak, nonatomic) IBOutlet WKWebView *webView;

@end

@implementation NewsFeedViewController

- (void)dealloc
{
    [_webView removeObserver:self forKeyPath:kKeyEstimatedProgress];
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
    _waitToken = [WaitToken new];
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
        if ([value isKindOfClass:[NSNumber class]] && value.doubleValue >= 1)
            _waitToken = nil;
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
