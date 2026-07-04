//
//  Walk.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/8/26.
//

#import <CoreLocation/CoreLocation.h>
@import GoogleMaps;
#import "Walk.h"
#import "WalkLocationFieldInfo.h"

/*
data class WalkData(
    val state: WalkState = WalkState.IDLE,
    val startTime: Long = System.currentTimeMillis(),
    val durationMilli: Long = 0,
    val distanceMeters: Double = 0.0,
    val startPosition: LatLng = DEFAULT_POSITION,
    val endPosition: LatLng = DEFAULT_END_POSITION,
    val path: List<LatLng> = emptyList<LatLng>(),
    val bounds: LatLngBounds = DEFAULT_BOUNDS,
    val bagsOfLitter: Int = 0,
    val imageUri: Uri = Uri.EMPTY
) {
    enum class WalkState {
        IDLE,
        IN_PROGRESS,
        COMPLETE,
        MOCK_LOCATION_DETECTED
    }
  */

#define kInitialPathCapacity 65536
#define kKeyState @"state"
#define kKeyStartTime @"startTime"
#define kKeyEndTime @"endTime"
#define kKeyFields @"fields"
#define kKeyImageFileName @"imageFileName"
#define kKeyBagCount @"bagCount"

@interface Walk ()
{
    NSURL *_fileUrl;
    FILE *_file;
    NSMutableArray<CLLocation *> *_mPath;
}

@property (strong, nonatomic) NSString *imageFileName;

@end

@implementation Walk

//@dynamic path;
@dynamic firstLocation;
@dynamic lastLocation;
@dynamic locationCount;

- (id)initWithFile:(NSURL *)fileUrl persistedFields:(NSArray<WalkLocationFieldInfo *> *)persistedFields
{
    if ((self = [super init]) != nil) {
        _fileUrl = fileUrl;
        const char *path = [fileUrl.path UTF8String];
        _file = fopen(path, "r+");
        if (_file != NULL && (fseek(_file, -1, SEEK_END) != 0 || ftell(_file) <= 0 || fgetc(_file) != '\n' || fseek(_file, 0, SEEK_SET) != 0 || ![self restore])) {
            fclose(_file);
            _file = NULL;
        }
        if (_file == NULL) {
            _file = fopen(path, "w");
            _mPath = [NSMutableArray arrayWithCapacity:kInitialPathCapacity];
        }
        NSArray<WalkLocationFieldInfo *> *oldFields = _persistedFields;
        NSArray<NSString *> *oldFieldNames = [self.class fieldNamesFromFields:oldFields];
        _persistedFields = [persistedFields copy];
        if (oldFieldNames != nil) {
            NSArray<NSString *> *fieldNames = [self.class fieldNamesFromFields:_persistedFields];
            if (fieldNames != nil && ![fieldNames isEqualToArray:oldFieldNames])
                [self saveState];
        }
    }
    return self;
}

- (NSURL *)imageFileUrl
{
    return [self imageFileUrlWithFileName:_imageFileName];
}

- (NSURL *)imageFileUrlWithFileName:(NSString *)fileName
{
    return fileName.length != 0 ? [[_fileUrl URLByDeletingLastPathComponent] URLByAppendingPathComponent:fileName] : nil;
}

- (void)flush
{
    _state = kWalkStateIdle;
    _startTime = nil;
    _endTime = nil;
    [_mPath removeAllObjects];
    if (_file != NULL)
        _file = freopen([_fileUrl.path UTF8String], "w", _file);
    NSURL *imageFileUrl = [self imageFileUrl];
    if (imageFileUrl != nil) {
        [[NSFileManager defaultManager] removeItemAtURL:imageFileUrl error:NULL];
        _imageFileName = nil;
    }
    _bagCount = nil;
}

+ (BOOL)restoreStateFromDictionary:(NSDictionary *)dictionary lastStatePtr:(WalkState *)lastStatePtr lastStartPtr:(NSDate **)lastStartPtr lastEndPtr:(NSDate **)lastEndPtr bagCountPtr:(NSNumber **)bagCountPtr lastImageFileNamePtr:(NSString **)lastImageFileNamePtr locationFieldsPtr:(NSArray<WalkLocationFieldInfo *> **)locationFieldsPtr;
{
    WalkState lastState = *lastStatePtr;
    NSDate *lastStart = *lastStartPtr;
    NSDate *lastEnd = *lastEndPtr;
    NSDictionary<NSString *, NSObject *> *header = (NSDictionary *)dictionary;
    NSArray<NSString *> *fieldNames = (NSArray<NSString *> *)header[kKeyFields];
    NSMutableArray<WalkLocationFieldInfo *> *currentFields = [NSMutableArray arrayWithCapacity:kNumWalkLocationFieldTypes];
    if ([fieldNames isKindOfClass:[NSArray class]]) {
        for (NSString *fieldName in fieldNames) {
            if ([fieldName isKindOfClass:[NSString class]]) {
                WalkLocationFieldInfo *info = [WalkLocationFieldInfo fieldInfoWithName:fieldName];
                if (info != nil) {
                    [currentFields addObject:info];
                    continue;
                }
            }
            return NO;
        }
    }
    if (currentFields.count != 0) {
        NSNumber *state = (NSNumber *)header[kKeyState];
        NSNumber *start = (NSNumber *)header[kKeyStartTime];
        NSNumber *end = (NSNumber *)header[kKeyEndTime];
        NSNumber *bagCount = (NSNumber *)header[kKeyBagCount];
        NSString *imageFileName = (NSString *)header[kKeyImageFileName];
        if ([state isKindOfClass:[NSNumber class]] && (start == nil || [start isKindOfClass:[NSNumber class]]) && (end == nil || [end isKindOfClass:[NSNumber class]]) && (bagCount == nil || [bagCount isKindOfClass:[NSNumber class]]) && (imageFileName == nil || [imageFileName isKindOfClass:[NSString class]])) {
            NSDate *potentialStart = nil;
            if (start != nil)
                potentialStart = [NSDate dateWithTimeIntervalSince1970:[start doubleValue]];
            
            NSDate *potentialEnd = nil;
            if (end != nil)
                potentialEnd = [NSDate dateWithTimeIntervalSince1970:[end doubleValue]];
            
            WalkState potentialState = (WalkState)[state integerValue];
            BOOL potentialStateIsGood = NO;
            switch (potentialState) {
                case kWalkStateIdle:
                    potentialStateIsGood = (lastState == kWalkStateIdle && potentialStart == nil && potentialEnd == nil);
                    break;
                case kWalkStateInProgress:
                    potentialStateIsGood = (lastState == kWalkStateIdle && potentialStart != nil && potentialEnd == nil);
                    break;
                case kWalkStateComplete:
                    potentialStateIsGood = ((lastState == kWalkStateInProgress || kWalkStateComplete) && potentialStart != nil && potentialEnd != nil && [lastStart isEqualToDate:potentialStart] && (lastEnd == nil || [lastEnd isEqualToDate:potentialEnd]));
                    break;
                case kWalkStateMockLocationDetected:
                    potentialStateIsGood = (lastState == kWalkStateInProgress && potentialStart != nil && potentialEnd == nil);
                    break;
            }
            if (potentialStateIsGood) {
                *lastStatePtr = potentialState;
                *lastStartPtr = potentialStart;
                *lastEndPtr = potentialEnd;
                *locationFieldsPtr = currentFields;
                *bagCountPtr = bagCount;
                *lastImageFileNamePtr = imageFileName;
                return YES;
            }
        }
    }
    return NO;
}

+ (CLLocation *)restoreLocationFromArray:(NSArray *)array fields:(NSArray<WalkLocationFieldInfo *> *)fields timestampOffset:(NSTimeInterval)timestampOffset
{
    NSUInteger count = array.count;
    if (count == fields.count) {
        CLLocation *defaultLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        CLLocationCoordinate2D coordinate = defaultLocation.coordinate;
        CLLocationDistance altitude = defaultLocation.altitude;
        CLLocationAccuracy horizontalAccuracy = defaultLocation.horizontalAccuracy;
        CLLocationAccuracy verticalAccuracy = defaultLocation.verticalAccuracy;
        CLLocationDirection course = defaultLocation.course;
        CLLocationDirectionAccuracy courseAccuracy = defaultLocation.courseAccuracy;
        CLLocationSpeed speed = defaultLocation.speed;
        CLLocationSpeedAccuracy speedAccuracy = defaultLocation.speedAccuracy;
        NSDate *timestamp = defaultLocation.timestamp;
        
        NSUInteger foundCount = 0;
        for (NSUInteger i = 0; i < count; ++i) {
            NSNumber *value = array[i];
            if ([value isKindOfClass:[NSNumber class]]) {
                double doubleValue = value.doubleValue;
                switch (fields[i].type) {
                    case kWalkLocationFieldTypeLatitude:
                        ++foundCount;
                        coordinate.latitude = (CLLocationDegrees)doubleValue;
                        break;
                    case kWalkLocationFieldTypeLongitude:
                        ++foundCount;
                        coordinate.longitude = (CLLocationDegrees)doubleValue;
                        break;
                    case kWalkLocationFieldTypeAltitude:
                        ++foundCount;
                        altitude = (CLLocationDistance)doubleValue;
                        break;
                    case kWalkLocationFieldTypeHorizontalAccuracy:
                        ++foundCount;
                        horizontalAccuracy = (CLLocationAccuracy)doubleValue;
                        break;
                    case kWalkLocationFieldTypeVerticalAccuracy:
                        ++foundCount;
                        verticalAccuracy = (CLLocationAccuracy)doubleValue;
                        break;
                    case kWalkLocationFieldTypeCourse:
                        ++foundCount;
                        course = (CLLocationDirection)doubleValue;
                        break;
                    case kWalkLocationFieldTypeCourseAccuracy:
                        ++foundCount;
                        courseAccuracy = (CLLocationDirectionAccuracy)doubleValue;
                        break;
                    case kWalkLocationFieldTypeSpeed:
                        ++foundCount;
                        speed = (CLLocationSpeed)doubleValue;
                        break;
                    case kWalkLocationFieldTypeSpeedAccuracy:
                        ++foundCount;
                        speedAccuracy = (CLLocationSpeedAccuracy)doubleValue;
                        break;
                    case kWalkLocationFieldTypeTimestamp:
                        ++foundCount;
                        timestamp = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)(doubleValue + timestampOffset)];
                        break;
                    case kNumWalkLocationFieldTypes:
                        break;
                }
            }
        }
        if (foundCount == count) {
            NSLog(@"restoring location with latitude %g, longitude %g, altitude %g, horizontalAccuracy %g, verticalAccuracy %g, course %g, courseAccuracy %g, speed %g, speedAccuracy %g, timestamp %@", coordinate.latitude, coordinate.longitude, altitude, horizontalAccuracy, verticalAccuracy, course, courseAccuracy, speed, speedAccuracy, timestamp);
            return [[CLLocation alloc] initWithCoordinate:coordinate altitude:altitude horizontalAccuracy:horizontalAccuracy verticalAccuracy:verticalAccuracy course:course courseAccuracy:courseAccuracy speed:speed speedAccuracy:speedAccuracy timestamp:timestamp];
        }
    }
    return nil;
}

- (BOOL)restore
{
    WalkState lastState = kWalkStateIdle;
    NSDate *lastStart = nil;
    NSDate *lastEnd = nil;
    NSMutableArray<CLLocation *> *path = [NSMutableArray arrayWithCapacity:kInitialPathCapacity];
    NSNumber *bagCount = nil;
    NSString *lastImageFileName = nil;

    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    BOOL parseError = NO;
    BOOL foundState = NO;
    NSMutableArray<WalkLocationFieldInfo *> *currentFields = nil;
    NSTimeInterval timestampOffset = 0;
    while ((read = getline(&line, &len, _file)) != -1 && read > 1) {
        NSData *jsonData = [NSData dataWithBytes:line length:read - 1];
        NSLog(@"Read from walk file: '%@'", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error == nil) {
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                if ([self.class restoreStateFromDictionary:(NSDictionary *)jsonObject lastStatePtr:&lastState lastStartPtr:&lastStart lastEndPtr:&lastEnd bagCountPtr:&bagCount lastImageFileNamePtr:&lastImageFileName locationFieldsPtr:&currentFields]) {
                    foundState = YES;
                    if (timestampOffset == 0 && lastStart != nil)
                        timestampOffset = [lastStart timeIntervalSince1970];
                    continue;
                }
            }
            else if ([jsonObject isKindOfClass:[NSArray class]]) {
                CLLocation *location = [self.class restoreLocationFromArray:(NSArray *)jsonObject fields:currentFields timestampOffset:timestampOffset];
                if (location != nil) {
                    //NSLog(@"restored location:\n%@", location);
                    [path addObject:location];
                    continue;
                }
            }
        }
        parseError = YES;
        break;
    }
    if (line != NULL)
        free(line);
    if (!parseError && foundState) {
        _state = lastState;
        _startTime = lastStart;
        _endTime = lastEnd;
        _mPath = path;
        _bagCount = bagCount;
        _imageFileName = lastImageFileName;
        _persistedFields = currentFields;
        return YES;
    }
    return NO;
}

- (void)writeToFile:(NSObject *)jsonObject
{
    if (_file != NULL) {
        NSMutableData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil].mutableCopy;
        NSLog(@"Writing to walk file: %@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
        [jsonData appendBytes:"\n" length:1];
        fwrite(jsonData.bytes, 1, jsonData.length, _file);
        fflush(_file);
    }
}

+ (NSArray<NSString *> *)fieldNamesFromFields:(NSArray<WalkLocationFieldInfo *> *)fields
{
    NSMutableArray<NSString *> *fieldNames = [NSMutableArray arrayWithCapacity:fields.count];
    for (WalkLocationFieldInfo *field in fields)
        [fieldNames addObject:field.name];
    return fieldNames.count != 0 ? fieldNames : nil;
}

- (void)saveState
{
    if (_file != NULL) {
        NSMutableDictionary<NSString *, NSObject *> *params = [NSMutableDictionary dictionaryWithCapacity:10];
        params[kKeyState] = @(_state);
        params[kKeyFields] = [self.class fieldNamesFromFields:_persistedFields];
        if (_startTime != nil)
            params[kKeyStartTime] = @([_startTime timeIntervalSince1970]);
        if (_endTime != nil)
            params[kKeyEndTime] = @([_endTime timeIntervalSince1970]);
        if (_bagCount != nil)
            params[kKeyBagCount] = _bagCount;
        if (_imageFileName != nil)
            params[kKeyImageFileName] = _imageFileName;
        [self writeToFile:params];
    }
}

+ (NSDecimalNumber *)roundedDecimalFromDouble:(double)value decimalPlaces:(NSUInteger)decimalPlaces
{
    NSDecimalNumberHandler *handler = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:decimalPlaces raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
    return [[[NSDecimalNumber alloc] initWithDouble:value] decimalNumberByRoundingAccordingToBehavior:handler];
}

+ (NSNumber *)numberFromLocation:(CLLocation *)location field:(WalkLocationFieldInfo *)field timestampOffset:(NSTimeInterval)timestampOffset
{
    double doubleValue = 0;
    switch (field.type) {
        case kWalkLocationFieldTypeLatitude:
            doubleValue = location.coordinate.latitude;
            break;
        case kWalkLocationFieldTypeLongitude:
            doubleValue = location.coordinate.longitude;
            break;
        case kWalkLocationFieldTypeAltitude:
            doubleValue = location.altitude;
            break;
        case kWalkLocationFieldTypeHorizontalAccuracy:
            doubleValue = location.horizontalAccuracy;
            break;
        case kWalkLocationFieldTypeVerticalAccuracy:
            doubleValue = location.verticalAccuracy;
            break;
        case kWalkLocationFieldTypeCourse:
            doubleValue = location.course;
            break;
        case kWalkLocationFieldTypeCourseAccuracy:
            doubleValue = location.courseAccuracy;
            break;
        case kWalkLocationFieldTypeSpeed:
            doubleValue = location.speed;
            break;
        case kWalkLocationFieldTypeSpeedAccuracy:
            doubleValue = location.speedAccuracy;
            break;
        case kWalkLocationFieldTypeTimestamp:
            doubleValue = [location.timestamp timeIntervalSince1970] - timestampOffset;
            break;
        case kNumWalkLocationFieldTypes:
            return nil;
    }
    return [self roundedDecimalFromDouble:doubleValue decimalPlaces:field.decimalDigits];
}

- (void)saveLocation:(CLLocation *)location timestampOffset:(NSTimeInterval)timestampOffset
{
    if (_file != NULL) {
        NSMutableArray<NSNumber *> *array = [NSMutableArray arrayWithCapacity:_persistedFields.count];
        for (WalkLocationFieldInfo *field in _persistedFields)
            [array addObject:[self.class numberFromLocation:location field:field timestampOffset:timestampOffset]];
        [self writeToFile:array];
    }
}

+ (GMSMutablePath *)pathFromLocations:(NSArray<CLLocation *> *)locations
{
    GMSMutablePath *path = [GMSMutablePath new];
    for (CLLocation *location in locations)
        [path addCoordinate:location.coordinate];
    return path;
}

- (GMSMutablePath *)gmsPath
{
    return [self.class pathFromLocations:_mPath];
}

+ (Walk *)restoreFromFile:(NSURL *)fileUrl
{
    NSData *data = [NSData dataWithContentsOfURL:fileUrl];
    if ([data isKindOfClass:[NSData class]]) {
        NSLog(@"restoring walk with %lu bytes of data", data.length);
        NSError *error = nil;
        Walk *walk = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[self class], [NSArray class], [NSDate class], [CLLocation class]]] fromData:data error:&error];
        if (error == nil && [walk isKindOfClass:[Walk class]])
            return walk;
    }
    return nil;
}

- (void)start
{
    if (_state == kWalkStateIdle) {
        _state = kWalkStateInProgress;
        _startTime = [NSDate date];
        [self saveState];
    }
}

- (void)stop
{
    if (_state == kWalkStateInProgress) {
        _state = kWalkStateComplete;
        _endTime = [NSDate date];
        [self saveState];
    }
}

- (void)addLocation:(CLLocation *)location
{
    if (_state == kWalkStateInProgress) {
        [_mPath addObject:location];
        [self saveLocation:location timestampOffset:[_startTime timeIntervalSince1970]];
    }
}

- (void)setBagCount:(NSNumber *)bagCount
{
    if (_state == kWalkStateComplete) {
        _bagCount = bagCount;
        [self saveState];
    }
}

- (void)saveImageData:(NSData *)imageData fileName:(NSString *)fileName completion:(void (^)(BOOL))completion
{
    if (_state == kWalkStateComplete) {
        NSAssert(![NSThread isMainThread], @"Should not be called from main thread");
        NSURL *imageFileUrl = [self imageFileUrlWithFileName:fileName];
        NSAssert(imageFileUrl != nil, @"Expected a file URL");
        BOOL succeeded = [imageData writeToURL:imageFileUrl atomically:YES];
        WEAK_SELF_PTR;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (succeeded) {
                weakSelf.imageFileName = fileName;
                [weakSelf saveState];
                completion(succeeded);
            }
        });
    }
}

- (void)readImageDataWithCompletion:(void (^)(NSData *data, UIImage *image))completion
{
    if (_state == kWalkStateComplete) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *imageFileUrl = [self imageFileUrl];
            NSData *data = nil;
            UIImage *image = nil;
            if (imageFileUrl != nil) {
                data = [NSData dataWithContentsOfURL:imageFileUrl];
                image = [UIImage imageWithData:data];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(data, image);
            });
        });
    }
}

- (NSTimeInterval)duration
{
    return _startTime != nil && _endTime != nil ? [_endTime timeIntervalSinceDate:_startTime] : 0;
}

/*
- (NSArray<CLLocation *> *)path
{
    return _mPath.count != 0 ? [NSArray arrayWithArray:_mPath] : @[];
}
 */

- (CLLocation *)firstLocation
{
    return _mPath.firstObject;
}

- (CLLocation *)lastLocation
{
    return _mPath.lastObject;
}

- (NSUInteger)locationCount
{
    return _mPath.count;
}

- (NSArray<CLLocation *> *)simplifiedPathWithTolerance:(CLLocationDistance)tolerance
{
    NSAssert(tolerance > 0, @"Expected a positive tolerance");
    if (self.locationCount <= 2)
        return [_mPath copy];
    NSMutableArray<CLLocation *> *mPath = _mPath.mutableCopy;
    [self.class adjustClosedPolygon:mPath];
    NSArray<NSNumber *> *pointsToKeep = [self.class douglasPeucker:mPath tolerance:tolerance];
    NSUInteger count = mPath.count;
    NSAssert(pointsToKeep.count == count, @"Expected counts to be the same.");
    for (NSInteger i = count - 1; i >= 0; --i)
        if (!pointsToKeep[i].boolValue)
            [mPath removeObjectAtIndex:i];
    NSLog(@"simplified path from %lu points to %lu points", count, mPath.count);
    return mPath;
}

+ (void)adjustClosedPolygon:(NSMutableArray<CLLocation *> *)path
{
    CLLocationCoordinate2D first = path.firstObject.coordinate;
    CLLocation *lastLocation = path.lastObject;
    CLLocationCoordinate2D last = lastLocation.coordinate;
    if (first.latitude == last.latitude && first.longitude == last.longitude) {
        const CLLocationDegrees epsilon = 0.00000000001;
        last.latitude += epsilon;
        last.longitude += epsilon;
        CLLocationSourceInformation *sourceInfo = lastLocation.sourceInformation;
        CLLocation *location = sourceInfo != nil ?
        [[CLLocation alloc] initWithCoordinate:last altitude:lastLocation.altitude horizontalAccuracy:lastLocation.horizontalAccuracy verticalAccuracy:lastLocation.verticalAccuracy course:lastLocation.course courseAccuracy:lastLocation.courseAccuracy speed:lastLocation.speed speedAccuracy:lastLocation.speedAccuracy timestamp:lastLocation.timestamp sourceInfo:lastLocation.sourceInformation] :
        [[CLLocation alloc] initWithCoordinate:last altitude:lastLocation.altitude horizontalAccuracy:lastLocation.horizontalAccuracy verticalAccuracy:lastLocation.verticalAccuracy course:lastLocation.course courseAccuracy:lastLocation.courseAccuracy speed:lastLocation.speed speedAccuracy:lastLocation.speedAccuracy timestamp:lastLocation.timestamp];
        [path replaceObjectAtIndex:path.count - 1 withObject:location];
    }
}

typedef struct {
    NSInteger start;
    NSInteger end;
} DPSegment;

+ (NSMutableArray<NSNumber *> *)douglasPeucker:(NSArray<CLLocation *> *)poly
                                     tolerance:(CLLocationDistance)tolerance
{
    NSInteger n = poly.count;
    NSAssert(n > 2, @"Path must have more than two locations to simplify");

    NSMutableArray<NSNumber *> *keep =
        [NSMutableArray arrayWithCapacity:n];

    for (NSInteger i = 0; i < n; i++)
        [keep addObject:@NO];

    keep[0] = @YES;
    keep[n - 1] = @YES;

    NSMutableArray<NSValue *> *stack = [NSMutableArray array];

    DPSegment initial = {0, n - 1};
    [stack addObject:[NSValue valueWithBytes:&initial objCType:@encode(DPSegment)]];

    while (stack.count > 0) {
        DPSegment segment;
        [[stack lastObject] getValue:&segment];
        [stack removeLastObject];

        double maxDist = 0.0;
        NSInteger maxIdx = NSNotFound;

        CLLocation *start = poly[segment.start];
        CLLocation *end = poly[segment.end];

        for (NSInteger i = segment.start + 1; i < segment.end; i++) {
            double dist = [self distanceToLine:poly[i] start:start end:end];
            if (dist > maxDist) {
                maxDist = dist;
                maxIdx = i;
            }
        }

        if (maxDist > tolerance) {
            keep[maxIdx] = @YES;
            DPSegment left = {segment.start, maxIdx};
            DPSegment right = {maxIdx, segment.end};
            [stack addObject:[NSValue valueWithBytes:&left objCType:@encode(DPSegment)]];
            [stack addObject:[NSValue valueWithBytes:&right objCType:@encode(DPSegment)]];
        }
    }

    return keep;
}

+ (CLLocationDistance)distanceToLine:(CLLocation *)p start:(CLLocation *)start end:(CLLocation *)end
{
    CLLocationCoordinate2D startCoordinate = start.coordinate;
    CLLocationCoordinate2D endCoordinate = end.coordinate;
    CLLocationCoordinate2D pCoordinate = p.coordinate;
    
    if (startCoordinate.latitude == endCoordinate.latitude &&
        startCoordinate.longitude == endCoordinate.longitude)
        return [p distanceFromLocation:end];

    double s0lat = start == nil ? 0.0 :
        pCoordinate.latitude * M_PI / 180.0;
    double s0lng = pCoordinate.longitude * M_PI / 180.0;

    double s1lat = startCoordinate.latitude * M_PI / 180.0;
    double s1lng = startCoordinate.longitude * M_PI / 180.0;

    double s2lat = endCoordinate.latitude * M_PI / 180.0;
    double s2lng = endCoordinate.longitude * M_PI / 180.0;

    double lonCorrection = cos(s1lat);

    double s2s1lat = s2lat - s1lat;
    double s2s1lng = (s2lng - s1lng) * lonCorrection;

    double u = (((s0lat - s1lat) * s2s1lat) + ((s0lng - s1lng) * lonCorrection * s2s1lng)) / ((s2s1lat * s2s1lat) + (s2s1lng * s2s1lng));

    if (u <= 0)
        return [p distanceFromLocation:start];

    if (u >= 1)
        return [p distanceFromLocation:end];

    CLLocationDegrees latitude = startCoordinate.latitude + (u * (endCoordinate.latitude - startCoordinate.latitude));

    CLLocationDegrees longitude = startCoordinate.longitude + (u * (endCoordinate.longitude - startCoordinate.longitude));

    return [p distanceFromLocation:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
}

@end
