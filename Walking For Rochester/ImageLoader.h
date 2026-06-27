//
//  ImageLoader.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/13/26.
//

#import <UIKit/UIKit.h>

@interface ImageLoader : NSObject

- (void)loadImageAtURL:(NSURL *)url completion:(void (^)(UIImage *))completion;

@end
