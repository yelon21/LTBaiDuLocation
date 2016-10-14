//
//  LTBaiDuLocation.h
//  LTBaiDuLocation
//
//  Created by yelon on 16/10/14.
//  Copyright © 2016年 yjpal. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BMKReverseGeoCodeResult;

@interface LTBaiDuLocation : NSObject

@property(nonatomic,assign,readonly) BOOL located;
@property(nonatomic,assign,readonly) BOOL locateEnable;

@property(nonatomic,strong,readonly) BMKReverseGeoCodeResult *reverseGeoCodeResult;

@property(nonatomic,assign,readonly) NSString *detailAddress;//详细地址

@property(nonatomic,assign,readonly) NSString *latitudeBaiDu;//bd纬度
@property(nonatomic,assign,readonly) NSString *longitudeBaiDu;//bd经度

@property(nonatomic,assign,readonly) NSString *briefAddress;//省|市|区|postalCode
@property(nonatomic,assign,readonly) NSString *city;

@property(nonatomic,strong) void(^LocationDisableBlock)();

+ (id)sharedLocation;

- (BOOL)lt_startWithBaiDuKey:(NSString *)key;
//开始定位
-(void)lt_startLocation;
//停止定位
-(void)lt_stopLocation;

@end
