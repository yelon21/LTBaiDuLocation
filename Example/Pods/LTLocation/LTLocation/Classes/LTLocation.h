//
//  LTLocation.h
//  LocationTest
//
//  Created by yelon on 14-5-5.
//  Copyright (c) 2014年 yelon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LTLocation : NSObject

@property(nonatomic,assign,readonly) BOOL located;
@property(nonatomic,assign,readonly) BOOL locateEnable;

@property(nonatomic,strong,readonly) CLPlacemark *currentPlacemark;
@property(nonatomic,strong,readonly) NSString *latitudeBaiDu;//bd纬度
@property(nonatomic,strong,readonly) NSString *longitudeBaiDu;//bd经度
@property(nonatomic,strong,readonly) NSString *latitudeGPS;//GPS纬度
@property(nonatomic,strong,readonly) NSString *longitudeGPS;//GPS经度
@property(nonatomic,strong,readonly) NSString *detailAddress;//详细地址
@property(nonatomic,strong,readonly) NSString *briefAddress;//省|市|区|postalCode
@property(nonatomic,strong,readonly) NSString *city;

@property(nonatomic,strong) void(^LocationDisableBlock)();

+ (id)sharedLocation;

//开始定位
-(void)lt_startLocation;
//停止定位
-(void)lt_stopLocation;
@end
