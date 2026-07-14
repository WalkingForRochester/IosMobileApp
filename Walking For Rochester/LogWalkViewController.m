//
//  LogWalkViewController.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 5/27/26.
//

#import <CoreLocation/CoreLocation.h>
@import GoogleMaps;
#import "LogWalkViewController.h"
#import "WaitToken.h"
#import "MainViewController.h"
#import "SafetyAndGuidelinesWaiverViewController.h"
#import "Walk.h"
#import "WalkLocationFieldInfo.h"
#import "FinishWalkViewController.h"
#import "SpoofDetectedViewController.h"

#define kMinZoom 9
#define kMaxZoom 20
#define kDefaultZoom 16
#define kMaxCameraAnimationDistance 1000
#define kDefaultTarget CLLocationCoordinate2DMake(43.1566, -77.6088)
#define kWalkFileName @"walk4.data"

// Used by isBetterLocation
#define kTimeIntervalMaxAgeDifference 2 * 60
#define kTimeIntervalRefresh 15
#define kMinimumAccuracyDelta 200
#define kMinimumMovedDistance 1

typedef enum {
    kLocationStateIdle = 0,
    kLocationStateRequestingAlways,
    kLocationStateRequestedAlways,
    kLocationStateUpdatingLocationWhileInApp,
    kLocationStateUpdatingLocationWhileInBackground
} LocationState;

@interface LogWalkViewController () <CLLocationManagerDelegate, GMSMapViewDelegate, SafetyAndGuidelinesWaiverViewControllerDelegate, FinishWalkViewControllerDelegate>
{
    CLLocationManager *_locationManager;
    CLAuthorizationStatus _locationAuthorizationStatus;
    CLAccuracyAuthorization _locationAccuracyAuthorization;
    CLLocation *_lastLocation;
    LocationState _internalLocationState;
    BOOL _isActive;
    BOOL _userMovedMap;
    Walk *_walk;
    GMSMarker *_walkStartMarker;
    GMSMutablePath *_walkPath;
    GMSPolyline *_walkPolyline;
    WaitToken *_waitToken;
}

@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *startStopButton;
@property (assign, nonatomic) LocationState locationState;
@property (assign, nonatomic) BOOL walkInProgress;

@end

@implementation LogWalkViewController

@dynamic locationState, walkInProgress;

+ (NSString *)locationStateToString:(LocationState)locationState;
{
    switch (locationState) {
        case kLocationStateIdle:
            return @"kLocationStateIdle";
        case kLocationStateRequestingAlways:
            return @"kLocationStateRequestingAlways";
        case kLocationStateRequestedAlways:
            return @"kLocationStateRequestedAlways";
        case kLocationStateUpdatingLocationWhileInApp:
            return @"kLocationStateUpdatingLocationWhileInApp";
        case kLocationStateUpdatingLocationWhileInBackground:
            return @"kLocationStateUpdatingLocationWhileInBackground";
    }
    return [NSString stringWithFormat:@"Unknown location state (%d)", (int)locationState];
}

+ (NSString *)locationAuthorizationStatusToString:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"kCLAuthorizationStatusNotDetermined";
        case kCLAuthorizationStatusRestricted:
            return @"kCLAuthorizationStatusRestricted";
        case kCLAuthorizationStatusDenied:
            return @"kCLAuthorizationStatusDenied";
        case kCLAuthorizationStatusAuthorizedAlways:
            return @"kCLAuthorizationStatusAuthorizedAlways";
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return @"kCLAuthorizationStatusAuthorizedAlways";
    }
    return [NSString stringWithFormat:@"Unknown authorization status (%d)", (int)status];
}

+ (NSString *)locationAccuracyAuthorizationToString:(CLAccuracyAuthorization)accuracy
{
    switch (accuracy) {
        case CLAccuracyAuthorizationFullAccuracy:
            return @"CLAccuracyAuthorizationFullAccuracy";
        case CLAccuracyAuthorizationReducedAccuracy:
            return @"CLAccuracyAuthorizationReducedAccuracy";
    }
    return [NSString stringWithFormat:@"Unknown accuracy authorization (%d)", (int)accuracy];
}

- (NSString *)locationStateString
{
    return [self.class locationStateToString:self.locationState];
}

- (void)setLocationState:(LocationState)locationState
{
    if (locationState != _internalLocationState) {
        NSLog(@"Changing location state from %@ to %@", [self locationStateString], [self.class locationStateToString:locationState]);
        if (locationState == kLocationStateRequestingAlways)
            _waitToken = [WaitToken new];
        else if (_internalLocationState == kLocationStateRequestingAlways)
            _waitToken = nil;
        _internalLocationState = locationState;
    }
}

- (LocationState)locationState
{
    return _internalLocationState;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]) != nil) {
        NSURL *pathUrl = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
        NSURL *walkFileUrl = [pathUrl URLByAppendingPathComponent:kWalkFileName];
        NSArray<WalkLocationFieldInfo *> *fields = @[
            [WalkLocationFieldInfo fieldInfoWithType:kWalkLocationFieldTypeLatitude decimalDigits:6],
            [WalkLocationFieldInfo fieldInfoWithType:kWalkLocationFieldTypeLongitude decimalDigits:6],
            [WalkLocationFieldInfo fieldInfoWithType:kWalkLocationFieldTypeTimestamp decimalDigits:3]
        ];
        _walk = [[Walk alloc] initWithFile:walkFileUrl persistedFields:fields];
        //[self flushWalk];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_mapView setMinZoom:kMinZoom maxZoom:kMaxZoom];
    [_mapView.settings setAllGesturesEnabled:NO];
    _mapView.delegate = self;
    _mapView.camera = [GMSCameraPosition cameraWithTarget:kDefaultTarget zoom:kDefaultZoom];
    if (self.walkInProgress) {
        [self addWalkStartMarker];
        [self addWalkPath];
    }
    
    // Interface Builder doesn't allow setting the button to have multiple states
    // as well as having the icon be on top. As a compromise, the image, title, font,
    // and background color are set in interface builder and then we use the code below
    // to switch to a button that allows a top icon with padding. The rest of the code is
    // needed to handle the font and the state switching.
    UIFont *font = _startStopButton.titleLabel.font;
    UIColor *color = _startStopButton.backgroundColor;
    UIButtonConfiguration *config = [UIButtonConfiguration plainButtonConfiguration];
    config.imagePlacement = NSDirectionalRectEdgeTop;
    config.imagePadding = 4;
    config.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey,id> * (NSDictionary<NSAttributedStringKey,id> *attributes) {
            NSMutableDictionary *mAttributes = [attributes mutableCopy];
            mAttributes[NSFontAttributeName] = font;
            return mAttributes;
        };
    _startStopButton.configuration = config;
    _startStopButton.configurationUpdateHandler = ^(UIButton *button) {
        UIButtonConfiguration *currentConfig = button.configuration;
        UIControlState currentState = button.state;
        currentConfig.title = [button titleForState:currentState];
        currentConfig.image = [button imageForState:currentState];
        currentConfig.baseBackgroundColor = color;
        button.configuration = currentConfig;
    };
    _startStopButton.selected = self.walkInProgress;
}

- (void)addWalkStartMarker
{
    NSAssert(_walkStartMarker == nil, @"Already have a start marker");
    _walkStartMarker = [GMSMarker markerWithPosition:_walk.firstLocation.coordinate];
    _walkStartMarker.icon = [UIImage imageNamed:@"image_trip_origin"];
    _walkStartMarker.groundAnchor = CGPointMake(0.5, 0.5);
    _walkStartMarker.map = _mapView;
}

- (void)addWalkPath
{
    NSAssert(_walkPath == nil, @"Already have a walk path");
    NSAssert(_walkPolyline == nil, @"Already have a walk polyline");
    if (_walk.locationCount >= 2) {
        _walkPath = [_walk gmsPath];
        _walkPolyline = [GMSPolyline polylineWithPath:_walkPath];
        _walkPolyline.strokeColor = [UIColor colorNamed:@"color_map_path"];
        _walkPolyline.strokeWidth = 6;
        _walkPolyline.map = _mapView;
    }
}

- (void)addLocationToWalk:(CLLocation *)location
{
    NSLog(@"adding to walk path: %f, %f", location.coordinate.latitude, location.coordinate.longitude);
    if ([_walk addLocation:location]) {
        NSUInteger locationCount = _walk.locationCount;
        NSAssert(locationCount > 1, @"Expected more than one location in walk");
        if (locationCount == 2)
            [self addWalkPath];
        else {
            [_walkPath addCoordinate:location.coordinate];
            _walkPolyline.path = _walkPath;
        }
    }
}

- (void)flushWalk
{
    [_walk flush];
    _walkPolyline.map = nil;
    _walkPolyline = nil;
    _walkPath = nil;
    _walkStartMarker.map = nil;
    _walkStartMarker = nil;
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position
{
    //NSLog(@"zoom is %g", position.zoom);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _isActive = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    if (_locationManager == nil) {
        _locationManager = [CLLocationManager new];
        _locationManager.allowsBackgroundLocationUpdates = YES;
        _locationManager.showsBackgroundLocationIndicator = YES;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        _locationManager.delegate = self;
        [self updateLocationAuthorizationStatusForce:YES];
    }
    WalkState state = _walk.state;
    if (state == kWalkStateComplete)
        [self showFinishWalkScreen];
    else if (state == kWalkStateMockLocationDetected)
        [self spoofDetected];
}

- (void)willResignActive:(NSNotification *)notification
{
    NSLog(@"entered: %@", NSStringFromSelector(_cmd));
    
    _isActive = NO;
    if (_locationManager != nil) {
        LocationState locationState = self.locationState;
        if (locationState == kLocationStateUpdatingLocationWhileInApp) {
            if (self.walkInProgress)
                self.locationState = kLocationStateUpdatingLocationWhileInBackground;
            else
                [self stopUpdatingLocation];
        }
        else if (locationState == kLocationStateRequestingAlways)
            self.locationState = kLocationStateRequestedAlways;
    }
    NSLog(@"exited: %@", NSStringFromSelector(_cmd));
}

- (void)didBecomeActive:(NSNotification *)notification
{
    NSLog(@"entered: %@", NSStringFromSelector(_cmd));
    _isActive = YES;
    if (_locationManager != nil) {
        NSLog(@"didBecomeActive, locationState is %@", [self locationStateString]);
        [self updateLocationAuthorizationStatusForce:YES];
    }
    NSLog(@"exited: %@", NSStringFromSelector(_cmd));
}

- (void)stopUpdatingLocation
{
    if (self.locationState == kLocationStateUpdatingLocationWhileInApp) {
        [_locationManager stopUpdatingLocation];
        _mapView.myLocationEnabled = NO;
        self.locationState = kLocationStateIdle;
    }
}

- (void)updateLocationAuthorizationStatusForce:(BOOL)force
{
    if (_isActive && (force || _locationAuthorizationStatus != _locationManager.authorizationStatus ||
                      _locationAccuracyAuthorization != _locationManager.accuracyAuthorization)) {
        CLLocationManager *locationManager = _locationManager;
        _locationAuthorizationStatus = locationManager.authorizationStatus;
        _locationAccuracyAuthorization = locationManager.accuracyAuthorization;
        BOOL fullAccuracy = _locationAccuracyAuthorization == CLAccuracyAuthorizationFullAccuracy;
        NSLog(@"_locationAuthorizationStatus is now %@, accuracy is %@", [self.class locationAuthorizationStatusToString:_locationAuthorizationStatus], [self.class locationAccuracyAuthorizationToString:_locationAccuracyAuthorization]);
        
        if (self.locationState == kLocationStateRequestedAlways) {
            self.locationState = kLocationStateUpdatingLocationWhileInApp;
            BOOL always = fullAccuracy && _locationAuthorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
            BOOL whenInUse = fullAccuracy && _locationAuthorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse;
            if (always || whenInUse) {
                WEAK_SELF_PTR;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (always)
                        [weakSelf startWalkCameraRequired:NO];
                    else
                        [weakSelf showAlwaysLocationAuthorizationRequired];
                });
                return;
            }
            else // We're back to square one after having been previously authorized.
                [self stopUpdatingLocation];
        }
        
        BOOL canUseLocation = NO;
        switch (_locationAuthorizationStatus) {
            case kCLAuthorizationStatusNotDetermined:
                if (self.locationState == kLocationStateIdle) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [locationManager requestWhenInUseAuthorization];
                    });
                    return;
                }
                break;
            case kCLAuthorizationStatusAuthorizedWhenInUse:
            case kCLAuthorizationStatusAuthorizedAlways:
                canUseLocation = fullAccuracy;
                break;
            case kCLAuthorizationStatusRestricted:
            case kCLAuthorizationStatusDenied:
                break;
        }
        
        if (canUseLocation) {
            if (self.locationState == kLocationStateUpdatingLocationWhileInBackground)
                self.locationState = kLocationStateUpdatingLocationWhileInApp;
            if (self.locationState != kLocationStateUpdatingLocationWhileInApp) {
                self.locationState = kLocationStateUpdatingLocationWhileInApp;
                [locationManager startUpdatingLocation];
                _mapView.myLocationEnabled = YES;
            }
        }
        else {
            if (self.locationState == kLocationStateUpdatingLocationWhileInApp || self.locationState == kLocationStateUpdatingLocationWhileInBackground)
                [self stopUpdatingLocation];
            if (self.locationState == kLocationStateIdle)
                [self showLocationRequired];
        }
    }
}

- (void)showLocationRequired
{
    NSAssert(self.locationState == kLocationStateIdle, @"Expected to be in idle location state");
    NSString *message = @"Walking for Rochester uses your precise location to display your position and current route while using the app.\n\nIn order to continue, you need to allow this permission in the Settings app.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Close app" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        exit(0);
    }]];
    WEAK_SELF_PTR;
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf.class launchSettingsApp];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlwaysLocationAuthorizationRequired
{
    NSAssert(self.locationState == kLocationStateUpdatingLocationWhileInApp, @"Expected to be in updating while in-app state");
    NSString *message = @"When you are on an active walk, Walking for Rochester records your progress even when the app is not in use.\n\nTo start a walk, you need to change the 'Share My Location' setting to 'Always' in the Settings app.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF_PTR;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        weakSelf.locationState = kLocationStateRequestingAlways;
        [LogWalkViewController launchSettingsApp];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

+ (void)launchSettingsApp
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    [self updateLocationAuthorizationStatusForce:NO];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    /*
     static NSDate *previous;
     NSDate *now = [NSDate date];
     if (previous != nil)
     NSLog(@"update interval %f", [now timeIntervalSinceDate:previous]);
     previous = now;
     */
    if (locations.count != 0) {
        CLLocation *location = locations[0];
        CLLocationDistance cameraMotionDistance = 0;
        if (_lastLocation == nil) {
            cameraMotionDistance = CLLocationDistanceMax;
            _lastLocation = location;
            GMSUISettings *settings = _mapView.settings;
            settings.myLocationButton = YES;
            settings.zoomGestures = YES;
            settings.scrollGestures = YES;
            settings.rotateGestures = YES;
        }
        else if ([self isBetterLocation:location]) {
            if (!_userMovedMap)
                cameraMotionDistance = [_lastLocation distanceFromLocation:location];
            _lastLocation = location;
            if (self.walkInProgress) {
                [self addLocationToWalk:location];
                WEAK_SELF_PTR;
                if (_walk.state == kWalkStateMockLocationDetected) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf spoofDetected];
                    });
                }
            }
        }
        if (cameraMotionDistance != 0) {
            GMSCameraUpdate *update = [GMSCameraUpdate setTarget:location.coordinate];
            if (cameraMotionDistance < kMaxCameraAnimationDistance)
                [_mapView animateWithCameraUpdate:update];
            else
                [_mapView moveCamera:update];
        }
    }
}

- (void)spoofDetected
{
    if (_walk.state == kWalkStateMockLocationDetected) {
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SpoofDetectedViewController"];
        [self presentViewController:vc animated:YES completion:^{
            self.walkInProgress = NO;
            [self flushWalk];
        }];
    }
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
    _userMovedMap = gesture;
}

// This was adapted from the Android app's method of the same name.
- (BOOL)isBetterLocation:(CLLocation *)location
{
    if (_lastLocation != nil) {
        NSTimeInterval timeDelta = [location.timestamp timeIntervalSinceDate:_lastLocation.timestamp];
        BOOL isSignificantlyNewer = timeDelta >= kTimeIntervalMaxAgeDifference;
        if (isSignificantlyNewer)
            return YES;
        BOOL isSignificantlyOlder = timeDelta <= -kTimeIntervalMaxAgeDifference;
        if (isSignificantlyOlder)
            return NO;
        CLLocationAccuracy accuracyDelta = location.horizontalAccuracy - _lastLocation.horizontalAccuracy;
        BOOL notSignificantlyLessAccurate = accuracyDelta <= kMinimumAccuracyDelta;
        if (timeDelta > 0) {
            if (accuracyDelta < 0)
                return YES;
            if (notSignificantlyLessAccurate && [location distanceFromLocation:_lastLocation] > kMinimumMovedDistance)
                return YES;
        }
        BOOL isRefreshTime = timeDelta >= kTimeIntervalRefresh;
        if (isRefreshTime) {
            if (accuracyDelta <= 0)
                return YES;
            if (notSignificantlyLessAccurate && [self isSameProvider:location])
                return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)isSameProvider:(CLLocation *)location
{
    if (_lastLocation != nil) {
        CLLocationSourceInformation *source = location.sourceInformation;
        CLLocationSourceInformation *lastSource = _lastLocation.sourceInformation;
        if (source != nil && lastSource != nil)
            return source.isProducedByAccessory == lastSource.isProducedByAccessory && source.isSimulatedBySoftware == lastSource.isSimulatedBySoftware;
        if (source == nil && lastSource == nil)
            return YES;
        return NO;
    }
    return YES;
}

- (void)startWalk
{
    [self startWalkCameraRequired:YES];
}

- (void)startWalkCameraRequired:(BOOL)cameraRequired
{
    if (!cameraRequired || [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if (_locationAuthorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
            SafetyAndGuidelinesWaiverViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SafetyAndGuidelinesWaiverViewController"];
            vc.delegate = self;
            [self presentViewController:vc animated:YES completion:nil];
        }
        else {
            self.locationState = kLocationStateRequestingAlways;
            [_locationManager requestAlwaysAuthorization];
            WEAK_SELF_PTR;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (weakSelf.locationState == kLocationStateRequestingAlways) {
                    
                    // The app never went inactive, which means the system didn't ask the user about
                    // upgrading to "always" location tracking. We have to ask them if they want
                    // to do this in Settings, instead. Note that there is no reliable way to detect this
                    // condition without using a timer or a delay, as we did above.
                    weakSelf.locationState = kLocationStateUpdatingLocationWhileInApp;
                    [weakSelf showAlwaysLocationAuthorizationRequired];
                }
            });
            return;
        }
    }
    else {
        NSString *message = @"Your device does not have a camera. A camera is required to submit a walk. Do you want to start a walk that you will not be able to submit for credit?";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No camera detected" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        WEAK_SELF_PTR;
        [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf startWalkCameraRequired:NO];
            });
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)safetyAndGuidelinesWaiverViewController:(SafetyAndGuidelinesWaiverViewController *)vc didCloseAndAcceptWaiver:(BOOL)accept
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if (accept)
        self.walkInProgress = YES;
}

- (void)endWalk
{
    NSString *message = @"Are you sure you want to end your walk and start the submission process?";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Stop your walk?" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF_PTR;
    [alert addAction:[UIAlertAction actionWithTitle:@"Keep walking" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"End walk" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf endWalkConfirmed];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)endWalkConfirmed
{
    self.walkInProgress = NO;
    [self showFinishWalkScreen];
}

- (void)showFinishWalkScreen
{
    FinishWalkViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FinishWalkViewController"];
    vc.delegate = self;
    vc.walk = _walk;
    WEAK_SELF_PTR;
    [self presentViewController:vc animated:YES completion:^{
        weakSelf.walkInProgress = NO;   // So flag doesn't change until the finish walk view controller is visible.
    }];
}

- (void)finishWalkViewControllerDidDiscardWalk:(FinishWalkViewController *)finishWalkViewController
{
    [self doneWithFinishWalkViewController];
}

- (void)finishWalkViewControllerDidUploadWalk:(FinishWalkViewController *)finishWalkViewController
{
    [self doneWithFinishWalkViewController];
}

- (void)doneWithFinishWalkViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self flushWalk];
}

- (void)setWalkInProgress:(BOOL)walkInProgress
{
    BOOL wasInProgress = _walk.state != kWalkStateIdle;
    if (wasInProgress != walkInProgress) {
        if (walkInProgress) {
            [_walk start];
            if ([_walk addLocation:_lastLocation])
                [self addWalkStartMarker];
            else
                [self spoofDetected];
        }
        else
            [_walk stop];
        _startStopButton.selected = walkInProgress;
    }
}

- (BOOL)walkInProgress
{
    return _walk != nil && _walk.state == kWalkStateInProgress;
}

- (IBAction)doStartStop:(id)button
{
    if (!self.walkInProgress)
        [self startWalk];
    else
        [self endWalk];
}

@end
