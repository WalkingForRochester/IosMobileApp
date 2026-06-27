//
//  WalkLocationFieldInfo.m
//  Walking For Rochester
//
//  Created by Lee Hasiuk on 6/15/26.
//

#import "WalkLocationFieldInfo.h"

@interface WalkLocationFieldInfo ()

@property (assign, nonatomic) WalkLocationFieldType type;
@property (assign, nonatomic) NSUInteger decimalDigits;

@end

@implementation WalkLocationFieldInfo

@dynamic name;

+ (NSString *)typeToName:(WalkLocationFieldType)type
{
    switch (type) {
        case kWalkLocationFieldTypeLatitude:
            return @"latitude";
        case kWalkLocationFieldTypeLongitude:
            return @"longitude";
        case kWalkLocationFieldTypeAltitude:
            return @"altitude";
        case kWalkLocationFieldTypeHorizontalAccuracy:
            return @"horizontalAccuracy";
        case kWalkLocationFieldTypeVerticalAccuracy:
            return @"verticalAccuracy";
        case kWalkLocationFieldTypeCourse:
            return @"course";
        case kWalkLocationFieldTypeCourseAccuracy:
            return @"courseAccuracy";
        case kWalkLocationFieldTypeSpeed:
            return @"speed";
        case kWalkLocationFieldTypeSpeedAccuracy:
            return @"speedAccuracy";
        case kWalkLocationFieldTypeTimestamp:
            return @"timestamp";
        case kNumWalkLocationFieldTypes:
            break;
    }
    return nil;
}

+ (WalkLocationFieldType)nameToType:(NSString *)name
{
    static dispatch_once_t onceToken;
    static NSDictionary<NSString *, NSNumber *> *fieldNameToType;

    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mFieldNameToType = [NSMutableDictionary dictionaryWithCapacity:kNumWalkLocationFieldTypes];
        for (NSUInteger i = 0; i < kNumWalkLocationFieldTypes; ++i) {
            WalkLocationFieldType type = (WalkLocationFieldType)i;
            mFieldNameToType[[self typeToName:type]] = @(type);
        }
        fieldNameToType = mFieldNameToType;
    });
    
    NSNumber *typeNumber = fieldNameToType[name];
    return typeNumber != nil ? (WalkLocationFieldType)typeNumber.unsignedIntegerValue : kNumWalkLocationFieldTypes;
}

+ (instancetype)fieldInfoWithType:(WalkLocationFieldType)type decimalDigits:(NSUInteger)decimalDigits
{
    WalkLocationFieldInfo *info = [WalkLocationFieldInfo new];
    info.type = type;
    info.decimalDigits = decimalDigits;
    return info;
}

+ (instancetype)fieldInfoWithName:(NSString *)name
{
    WalkLocationFieldInfo *info = nil;
    WalkLocationFieldType type = [self nameToType:name];
    if (type != kNumWalkLocationFieldTypes) {
        info = [WalkLocationFieldInfo new];
        info.type = type;
        info.decimalDigits = NSNotFound;
    }
    return info;
}

- (NSString *)name
{
    return [self.class typeToName:_type];
}

@end
