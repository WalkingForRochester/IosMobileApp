//
//  Walk.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/8/26.
//

#import <Foundation/Foundation.h>

typedef enum {
    kWalkStateIdle = 0,
    kWalkStateInProgress,
    kWalkStateComplete,
    kWalkStateMockLocationDetected
} WalkState;

@class CLLocation;
@class GMSMutablePath;
@class WalkLocationFieldInfo;

@interface Walk : NSObject

- (id)initWithFile:(NSURL *)fileUrl persistedFields:(NSArray<WalkLocationFieldInfo *> *)persistedFields;

+ (GMSMutablePath *)pathFromLocations:(NSArray<CLLocation *> *)locations;

- (NSArray<CLLocation *> *)simplifiedPathWithTolerance:(CLLocationDistance)tolerance;
- (GMSMutablePath *)gmsPath;

- (NSTimeInterval)duration;

- (void)start;
- (void)stop;
- (void)addLocation:(CLLocation *)location;
- (void)saveImageData:(NSData *)imageData fileName:(NSString *)fileName completion:(void (^)(BOOL succeeded))completion;
- (void)readImageDataWithCompletion:(void (^)(NSData *data, UIImage *image))completion;
- (void)flush;

@property (assign, nonatomic) WalkState state;
@property (strong, nonatomic, readonly) NSDate *startTime;
@property (strong, nonatomic, readonly) NSDate *endTime;
@property (strong, nonatomic) NSNumber *bagCount;
@property (strong, nonatomic, readonly) NSString *imageFileName;
//@property (strong, nonatomic, readonly) NSArray<CLLocation *> *path;
@property (strong, nonatomic, readonly) CLLocation *firstLocation;
@property (strong, nonatomic, readonly) CLLocation *lastLocation;
@property (assign, nonatomic, readonly) NSUInteger locationCount;
@property (strong, nonatomic, readonly) NSArray<WalkLocationFieldInfo *> *persistedFields;

@end
