//
//  ImageLoader.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import "ImageLoader.h"
#import "NSCache+Extensions.h"

static NSCache<NSURL *, UIImage *> *s_memoryCache;

@interface ImageLoader ()

@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@property (strong, nonatomic) void (^completion)(UIImage *image);

@end

@implementation ImageLoader

+ (void)load
{
    s_memoryCache = [NSCache new];
}

- (void)dealloc
{
    [_dataTask cancel];
}

- (void)loadImageAtURL:(NSURL *)url completion:(void (^)(UIImage *))completion
{
    if (_dataTask != nil) {
        [_dataTask cancel];
        _dataTask = nil;
    }
    WEAK_SELF_PTR;
    _completion = completion;
    UIImage *image = s_memoryCache[url];
    if (image != nil)
        dispatch_async(dispatch_get_main_queue(), ^{
            void (^completion)(UIImage *image) = weakSelf.completion;
            if (completion != nil)
                completion(image);
        });
    else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        _dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            weakSelf.dataTask = nil;
            UIImage *image = nil;
            if (error == nil && data.length != 0) {
                image = [UIImage imageWithData:data];
                if (image != nil)
                    s_memoryCache[url] = image;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                void (^completion)(UIImage *image) = weakSelf.completion;
                if (completion != nil)
                    completion(image);
            });
        }];
        [_dataTask resume];
    }
}
 
@end
