//
//  FinishWalkViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/15/26.
//

#import <CoreLocation/CoreLocation.h>
#import <AVFoundation/AVFoundation.h>
//#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "FinishWalkViewController.h"
#import "Walk.h"
#import "ProfileStatisticsTableViewCell.h"
#import "LogWalkViewController.h"
#import "ProfileEditorViewController.h"
#import "WaitToken.h"
#import "APIManager.h"

@import GoogleMaps;

#define kSimplifiedPathTolerance 1
#define kBagCountUpdateDelay 2

@interface FinishWalkViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    CLLocationDistance _distance;
    NSTimeInterval _duration;
    NSUInteger _bagCount;
    NSTimer *_bagCountUpdateTimer;
    NSString *_encodedPath;
    NSData *_imageData;
    WaitToken *_waitToken;
}

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIStepper *bagsStepper;
@property (weak, nonatomic) IBOutlet UILabel *bagsLabel;
@property (weak, nonatomic) IBOutlet UIStackView *cameraStackView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;

@end

@implementation FinishWalkViewController

- (void)dealloc
{
    [_bagCountUpdateTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (GMSMarker *)addMarkerWithIconImage:(UIImage *)iconImage coordinate:(CLLocationCoordinate2D)coordinate groundAnchor:(CGPoint)groundAnchor zIndex:(int)zIndex
{
    GMSMarker *marker = [GMSMarker markerWithPosition:coordinate];
    marker.icon = iconImage;
    marker.groundAnchor = groundAnchor;
    marker.zIndex = zIndex;
    marker.map = _mapView;
    return marker;
}

+ (GMSCoordinateBounds *)fixedBoundsWithCoordinate:(CLLocationCoordinate2D)coordinate distanceToCorner:(CLLocationDistance)distance
{
    CLLocationCoordinate2D southwest = GMSGeometryOffset(coordinate, distance, 225);
    CLLocationCoordinate2D northeast = GMSGeometryOffset(coordinate, distance, 45);
    return [[GMSCoordinateBounds alloc] initWithCoordinate:southwest coordinate:northeast];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(_walk != nil, @"Expected the walk to be set by the time the view loads");
    NSAssert(_walk.state == kWalkStateComplete, @"Expected the walk state to be complete");
    
    NSArray<CLLocation *> *simplifiedPath = [_walk simplifiedPathWithTolerance:kSimplifiedPathTolerance];
    NSAssert(simplifiedPath.count >= 2, @"Expected at least two points on path");
    
    GMSPath *path = [Walk pathFromLocations:simplifiedPath];
    _encodedPath = path.encodedPath;
    NSLog(@"encoded path is %@", _encodedPath);
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeColor = [UIColor colorNamed:@"color_map_path"];
    polyline.strokeWidth = 6;
    polyline.map = _mapView;
    
    _distance = [path lengthOfKind:kGMSLengthGeodesic];
    _distanceLabel.text = [ProfileStatisticsTableViewCell formatDistanceInMeters:@(_distance)];
    _duration = [_walk duration];
    _durationLabel.text = [ProfileStatisticsTableViewCell formatDurationInSeconds:@(_duration)];

    int zIndex = 10;
    CLLocationCoordinate2D startCoordinate = simplifiedPath.firstObject.coordinate;
    CLLocationCoordinate2D endCoordinate = simplifiedPath.lastObject.coordinate;
    [self addMarkerWithIconImage:[UIImage imageNamed:@"image_trip_origin"] coordinate:startCoordinate groundAnchor:CGPointMake(0.5, 0.5) zIndex:zIndex++];
    [self addMarkerWithIconImage:[UIImage imageNamed:@"image_trip_destination"] coordinate:endCoordinate groundAnchor:CGPointMake(0.5, 0.5) zIndex:zIndex++];
    [self addMarkerWithIconImage:[GMSMarker markerImageWithColor:[UIColor redColor]] coordinate:endCoordinate groundAnchor:CGPointMake(0.5, 1.0) zIndex:zIndex];

    GMSCoordinateBounds *bounds = [self.class fixedBoundsWithCoordinate:startCoordinate distanceToCorner:50];
    bounds = [bounds includingBounds:[self.class fixedBoundsWithCoordinate:endCoordinate distanceToCorner:50]];
    bounds = [bounds includingPath:path];
    _mapView.camera = [_mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(64, 64, 64, 64)];
    
    _bagCount = _walk.bagCount.unsignedIntegerValue;
    _bagsStepper.value = _bagCount;
    [self refreshBagCountDisplay];
    
    _cameraStackView.hidden = NO;
    _retakeButton.alpha = 0;
    if (_walk.imageFileName.length != 0) {
        WEAK_SELF_PTR;
        [_walk readImageDataWithCompletion:^(NSData *data, UIImage *image) {
            [weakSelf didCompressImage:image data:data succeeded:image != nil];
        }];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)willResignActive:(NSNotification *)notification
{
    if (_bagCountUpdateTimer != nil) {
        [_bagCountUpdateTimer invalidate];
        _bagCountUpdateTimer = nil;
        [self saveBagCount];
    }
}

- (void)refreshBagCountDisplay
{
    _bagsLabel.text = [NSString stringWithFormat:@"%lu", _bagCount];
}

- (IBAction)bagsCountChanged:(UIStepper *)sender
{
    _bagCount = (NSUInteger)sender.value;
    [self refreshBagCountDisplay];
    if (_bagCountUpdateTimer == nil)
        _bagCountUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:kBagCountUpdateDelay target:self selector:@selector(bagCountUpdateTimerFired) userInfo:nil repeats:NO];
    else
        _bagCountUpdateTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:kBagCountUpdateDelay];
}

- (void)bagCountUpdateTimerFired
{
    _bagCountUpdateTimer = nil;
    [self saveBagCount];
}

- (void)saveBagCount
{
    NSNumber *currentCount = _walk.bagCount;
    if ((currentCount == nil && _bagCount != 0) || (currentCount != nil && currentCount.unsignedIntegerValue != _bagCount))
        _walk.bagCount = @(_bagCount);
}

- (IBAction)doTakePhoto:(id)sender
{
    [self takePhoto];
}

- (void)takePhoto
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusAuthorized) {
            UIImagePickerController *picker = [UIImagePickerController new];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            picker.cameraFlashMode = UIImagePickerControllerCameraFlashModeAuto;
            
            [self presentViewController:picker animated:YES completion:nil];
        }
        else if (status == AVAuthorizationStatusNotDetermined) {
            WEAK_SELF_PTR;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf takePhoto];
                });
            }];
        }
        else {
            NSString *message = @"In order to submit your walk we need you to take a picture of the litter you collected.\n\nIn order to continue, you need to allow this permission in the Settings app.";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera" message:message preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

            [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [LogWalkViewController launchSettingsApp];
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else {
        NSString *message = @"Your device does not have a camera.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    NSAssert([NSThread isMainThread], @"Expected main thread");
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    /*
    NSDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    NSLog(@"info:\n%@\nmetadata:\n%@", info, metadata);
    */
    _waitToken = [WaitToken new];
    if ([image isKindOfClass:[UIImage class]]) {
        WEAK_SELF_PTR;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *compressedImage = nil;
            NSData *data = [ProfileEditorViewController compressImage:image targetDimension:1024 quality:0.75 compressedImagePtr:&compressedImage];
            NSLog(@"compressed image size without metadata is %lu, dimensions %@", data.length, NSStringFromCGSize(compressedImage.size));
            NSString *fileName = nil;
            if (data.length != 0) {
                // In case we need the metadata at some point
#if 0
                if (metadata.count != 0) {
                    NSMutableData *mutableData = [NSMutableData dataWithCapacity:data.length + 8192];
                    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
                    if (source != NULL) {
                        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, (__bridge CFStringRef)UTTypeJPEG.identifier, 1, NULL);
                        
                        if (destination != NULL) {
                            CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef)metadata);
                            CGImageDestinationFinalize(destination);
                            CFRelease(destination);
                            data = mutableData;
                        }
                        CFRelease(source);
                    }
                }
#endif
                
                fileName = weakSelf.walk.imageFileName;
                if (fileName.length == 0)
                    fileName = [NSString stringWithFormat:@"%@.jpg", [[NSUUID UUID].UUIDString lowercaseString]];
                NSLog(@"compressed image size is %lu, dimensions %@, name is %@", data.length, NSStringFromCGSize(compressedImage.size), fileName);
            }
            [weakSelf.walk saveImageData:data fileName:fileName completion:^(BOOL succeeded) {
                NSAssert([NSThread isMainThread], @"Expected main thread");
                [weakSelf didCompressImage:compressedImage data:data succeeded:succeeded];
            }];
        });
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didCompressImage:(UIImage *)image data:(NSData *)data succeeded:(BOOL)succeeded
{
    _waitToken = nil;
    if (image != nil) {
        _imageData = data;
        _cameraStackView.hidden = YES;
        _imageView.image = image;
        _retakeButton.alpha = 1;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSAssert([NSThread isMainThread], @"Expected main thread");
    [self dismissViewControllerAnimated:YES completion:nil];
}
    
- (IBAction)doCancelWalk:(id)sender
{
    NSString *message = @"Are you sure you do not want to submit your walk?";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discard walk" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF_PTR;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Discard" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf discardWalk];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)doSubmitWalk:(id)sender
{
    if (_imageView.image != nil && _imageData.length != 0) {
        WEAK_SELF_PTR;
        [[APIManager sharedAPIManager] uploadImageWithType:kAPIManagerImageFileTypeLitter data:_imageData completion:^(APIManagerCall *call, NSURL *imgUrl, NSError *error) {
            [weakSelf didUploadImageWithUrl:imgUrl error:error];
        }];
    }
    else {
        NSString *message = @"A photo is required in order to submit your walk.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didUploadImageWithUrl:(NSURL *)url error:(NSError *)error
{
    NSLog(@"uploaded image to %@, error %@", url, error);
    if (error == nil && url != nil) {
        // XXX could save image URL to walk file so it doesn't need to be uploaded again if walk upload fails unless user chooses another image.
        WEAK_SELF_PTR;
        [[APIManager sharedAPIManager] logWalkWithDistance:_distance duration:_duration bags:_bagCount imageUrl:url encodedPath:_encodedPath completion:^(APIManagerCall *call, BOOL succeeded, NSError *error) {
            [weakSelf didUploadWalk:succeeded error:error];
        }];
    }
}

- (void)didUploadWalk:(BOOL)succeeded error:(NSError *)error
{
    NSLog(@"didUploadWalk: succeeded %d. error:\n%@", (int)succeeded, error);
    if (error == nil && succeeded)
        [_delegate finishWalkViewControllerDidUploadWalk:self];
}

- (void)discardWalk
{
    [_delegate finishWalkViewControllerDidDiscardWalk:self];
}

/*
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.view layoutIfNeeded];
    } completion:nil];
}
 */

@end
