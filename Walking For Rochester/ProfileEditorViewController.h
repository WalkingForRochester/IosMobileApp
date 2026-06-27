//
//  ProfileEditorViewController.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/18/26.
//

#import <UIKit/UIKit.h>

@class ProfileViewController;

@interface ProfileEditorViewController : UIViewController

+ (NSData *)compressImage:(UIImage *)image targetDimension:(NSUInteger)targetDimension quality:(CGFloat)quality compressedImagePtr:(UIImage **)compressedImagePtr;

@property (weak, nonatomic) ProfileViewController *profileViewController;

@end

