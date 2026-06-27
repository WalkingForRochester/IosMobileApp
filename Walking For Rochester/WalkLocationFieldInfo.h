//
//  WalkLocationFieldInfo.h
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/15/26.
//

#import <Foundation/Foundation.h>

typedef enum {
    kWalkLocationFieldTypeLatitude = 0,
    kWalkLocationFieldTypeLongitude,
    kWalkLocationFieldTypeAltitude,
    kWalkLocationFieldTypeHorizontalAccuracy,
    kWalkLocationFieldTypeVerticalAccuracy,
    kWalkLocationFieldTypeCourse,
    kWalkLocationFieldTypeCourseAccuracy,
    kWalkLocationFieldTypeSpeed,
    kWalkLocationFieldTypeSpeedAccuracy,
    kWalkLocationFieldTypeTimestamp,
    kNumWalkLocationFieldTypes
} WalkLocationFieldType;

@interface WalkLocationFieldInfo : NSObject

+ (instancetype)fieldInfoWithType:(WalkLocationFieldType)type decimalDigits:(NSUInteger)decimalDigits;

+ (instancetype)fieldInfoWithName:(NSString *)name;

@property (assign, nonatomic, readonly) WalkLocationFieldType type;
@property (assign, nonatomic, readonly) NSUInteger decimalDigits;
@property (strong, nonatomic, readonly) NSString *name;

@end
