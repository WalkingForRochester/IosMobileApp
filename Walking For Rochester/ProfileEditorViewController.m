//
//  ProfileEditorViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/18/26.
//

#import <PhotosUI/PhotosUI.h>
#import "ProfileEditorViewController.h"
#import "SignUpFieldView.h"
#import "RoundImageView.h"
#import "ImageLoader.h"
#import "Profile.h"
#import "ProfileViewController.h"
#import "HomeViewController.h"
#import "MainViewController.h"
#import "NSString+Extensions.h"

@interface ProfileEditorViewController () <SignUpFieldViewDelegate, /*UINavigationControllerDelegate, UIImagePickerControllerDelegate*/ PHPickerViewControllerDelegate>
{
    ImageLoader *_imageLoader;
    NSData *_pendingProfileImageData;
    Profile *_profile;
    UINavigationItem __weak *_navigationItem;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet RoundImageView *profileImageView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *emailView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *phoneView;
@property (weak, nonatomic) IBOutlet SignUpFieldView *displayNameView;
@property (weak, nonatomic) IBOutlet UISwitch *communityServiceSwitch;

@end

@implementation ProfileEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(_profileViewController != nil, @"Expected a profile view controller");
    _profile = _profileViewController.profile;
    NSURL *imageUrl = _profile.imgUrl;
    if (imageUrl != nil) {
        _imageLoader = [ImageLoader new];
        WEAK_SELF_PTR;
        [_imageLoader loadImageAtURL:imageUrl completion:^(UIImage *image) {
            weakSelf.profileImageView.image = image;
        }];
    }
    _emailView.text = _profile.email;
    _phoneView.text = [_profile.phoneNumber tenDigitFormattedPhoneNumber];
    _displayNameView.text = _profile.nickname;
    _communityServiceSwitch.on = _profile.communityService;
    _navigationItem = [MainViewController sharedMainViewController].navigationController.topViewController.navigationItem;
    _navigationItem.leftBarButtonItem = _cancelBarButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (BOOL)signUpFieldViewIsContentValid:(SignUpFieldView *)signUpFieldView text:(NSString *)text
{
    if (signUpFieldView == _emailView)
        return [text isValidEmailAddress];
    else if (signUpFieldView == _phoneView)
        return [text decimalDigits].length == 10;
    else if (signUpFieldView == _displayNameView)
        return YES;
    NSAssert(NO, @"Field not handled");
    return NO;
}

- (BOOL)signUpFieldView:(SignUpFieldView *)signUpFieldView textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (signUpFieldView == _phoneView) {
        NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
        textField.text = [text tenDigitFormattedPhoneNumber];
        UITextPosition *end = textField.endOfDocument;
        textField.selectedTextRange = [textField textRangeFromPosition:end toPosition:end];
        [_phoneView clearError];
        return NO;
    }
    return YES;
}

- (IBAction)doChoosePhoto:(id)sender
{
    PHPickerConfiguration *config = [PHPickerConfiguration new];
    config.selectionLimit = 1;
    config.filter = PHPickerFilter.imagesFilter;
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

+ (NSData *)compressImage:(UIImage *)image targetDimension:(NSUInteger)targetDimension quality:(CGFloat)quality compressedImagePtr:(UIImage **)compressedImagePtr
{
    NSAssert(![NSThread isMainThread], @"Expected background thread.");
    CGSize imageSize = image.size;
    if (imageSize.width != targetDimension || imageSize.height != targetDimension) {
        CGFloat aspectRatio = imageSize.width / imageSize.height;
        CGSize targetSize;
        if (aspectRatio > 1) {
            targetSize.width = MIN(imageSize.width, targetDimension);
            targetSize.height = round(targetSize.width / aspectRatio);
        }
        else {
            targetSize.height = MIN(imageSize.height, targetDimension);
            targetSize.width = round(targetSize.height * aspectRatio);
        }
        image = [image imageByPreparingThumbnailOfSize:targetSize];
    }
    NSData *compressedImageData = UIImageJPEGRepresentation(image, quality);
    if (compressedImagePtr != NULL)
        *compressedImagePtr = [UIImage imageWithData:compressedImageData];
    return compressedImageData;
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (results.count != 0) {
        NSItemProvider *provider = results.firstObject.itemProvider;
        Class imageClass = [UIImage class];
        if ([provider canLoadObjectOfClass:imageClass]) {
            WEAK_SELF_PTR;
            [HomeViewController sharedHomeViewController].busyCount += 1;
            [provider loadObjectOfClass:imageClass completionHandler:^(id<NSItemProviderReading> object, NSError *error) {
                NSAssert(![NSThread isMainThread], @"Expected background thread.");
                if (error == nil && [object isKindOfClass:imageClass]) {
                    UIImage *image = nil;
                    NSData *data = [weakSelf.class compressImage:(UIImage *)object targetDimension:500 quality:0.75 compressedImagePtr:&image];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf displayReplacementThumbnailImage:image data:data];
                    });
                }
            }];
        }
    }
}

- (void)displayReplacementThumbnailImage:(UIImage *)image data:(NSData *)data
{
    [HomeViewController sharedHomeViewController].busyCount -= 1;
    if (image != nil && data.length != 0) {
        _profileImageView.image = image;
        _pendingProfileImageData = data;
    }
}

- (IBAction)doCancel:(id)sender
{
    [self pop];
}

- (IBAction)doSave:(id)sender
{
    if ([_emailView validateAll]) {
        [_emailView resignAll];
        ProfileUpdate *update = [ProfileUpdate new];
        update.email = _emailView.text;
        update.phone = [_phoneView.text decimalDigits];
        update.nickname = _displayNameView.text;
        update.communityService = _communityServiceSwitch.on;
        
        if (_pendingProfileImageData != nil) {
            WEAK_SELF_PTR;
            [[APIManager sharedAPIManager] uploadImageWithType:kAPIManagerImageFileTypeProfile data:_pendingProfileImageData completion:^(APIManagerCall *call, NSURL *imgUrl, NSError *error) {
                [weakSelf finishProfileUpdate:update withImageUrl:imgUrl];
            }];
        }
        else
            [self finishProfileUpdate:update withImageUrl:_profile.imgUrl];
    }
}
    
- (void)finishProfileUpdate:(ProfileUpdate *)update withImageUrl:(NSURL *)imgUrl
{
    if (imgUrl != nil) {
        update.imgUrl = imgUrl;
        NSLog(@"updated profile:\n%@", update.dictionary);
        WEAK_SELF_PTR;
        [[APIManager sharedAPIManager] updateProfileWith:update completion:^(APIManagerCall *call, BOOL succeeded, NSError *error) {
            if (succeeded) {
                [weakSelf.profileViewController refresh];
                [weakSelf pop];
            }
        }];
    }
}

- (void)pop
{
    [self.navigationController popViewControllerAnimated:YES];
    if (_navigationItem.leftBarButtonItem == _cancelBarButtonItem)
        _navigationItem.leftBarButtonItem = nil;
}

@end
