//
//  ProfileEditorViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/18/26.
//

#import "KeyboardFixViewController.h"

@class ProfileViewController;

@interface ProfileEditorViewController : KeyboardFixViewController

+ (NSData *)compressImage:(UIImage *)image targetDimension:(NSUInteger)targetDimension quality:(CGFloat)quality compressedImagePtr:(UIImage **)compressedImagePtr;

@property (weak, nonatomic) ProfileViewController *profileViewController;

@end

