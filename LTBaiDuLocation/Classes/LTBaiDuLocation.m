//
//  LTBaiDuLocation.m
//  LTBaiDuLocation
//
//  Created by yelon on 16/10/14.
//  Copyright © 2016年 yjpal. All rights reserved.
//

#import "LTBaiDuLocation.h"
#import <BMKLocationKit/BMKLocationComponent.h>
#import "LTLocation.h"

@interface LTBaiDuLocation ()<BMKLocationAuthDelegate,BMKLocationManagerDelegate>{

    BMKLocationManager* _locationManager;
    
    BOOL permissionSucceed;
    
    LTLocation *ltlocation;
}

@property(nonatomic,strong) BMKLocationManager *locationManager;

@property(nonatomic,strong,readwrite) BMKLocation *currentLocation;

@property(nonatomic,assign,readwrite) NSString *detailAddress;//详细地址

@end


@implementation LTBaiDuLocation
@synthesize locationManager = _locationManager;

+ (id)sharedLocation{
    
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        
        sharedInstance = [[LTBaiDuLocation alloc] init];
    });
    return sharedInstance;
}
-(NSString *)debugDescription{
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"latitudeBaiDu"] = self.latitudeBaiDu;
    dictionary[@"longitudeBaiDu"] = self.longitudeBaiDu;
    dictionary[@"briefAddress"] = self.briefAddress;
    dictionary[@"detailAddress"] = self.detailAddress;
    dictionary[@"city"] = self.city;
    
    NSArray *keys = [dictionary allKeys];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (NSString *key in keys) {
        
        [array addObject:[NSString stringWithFormat:@"%@:%@",key,dictionary[key]]];
    }
    NSString *description = [NSString stringWithFormat:@"\n%@",[array componentsJoinedByString:@"\n"]];
    return description;
}
-(id)init{
    
    if (self = [super init]) {
        
        permissionSucceed = NO;
        
        //初始化实例
        _locationManager = [[BMKLocationManager alloc] init];
        //设置delegate
        _locationManager.delegate = self;
        //设置返回位置的坐标系类型
        _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
        //设置距离过滤参数
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        //设置预期精度参数
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //设置应用位置类型
        _locationManager.activityType = CLActivityTypeOther;
        //设置是否自动停止位置更新
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        //设置是否允许后台定位
        //_locationManager.allowsBackgroundLocationUpdates = YES;
        //设置位置获取超时时间
        _locationManager.locationTimeout = 10;
        //设置获取地址信息超时时间
        _locationManager.reGeocodeTimeout = 10;
    }
    
    return self;
}

- (void)lt_startWithBaiDuKey:(NSString *)key{

    if (!key || ![key isKindOfClass:[NSString class]]||[key length]==0) {
        
        NSLog(@"百度定位Key异常：%@",key);
        return;
    }
    
    if(!permissionSucceed){
    
        [[BMKLocationAuth sharedInstance] checkPermisionWithKey:key
                                                   authDelegate:self];
    }
}

//开始定位
-(void)lt_startLocation{

    if (permissionSucceed) {
        
//        _locService.delegate = self;
        [self.locationManager setLocatingWithReGeocode:YES];
        [self.locationManager startUpdatingLocation];
    }
    else{
    
        if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
            
            [ltlocation lt_startLocation];
        }
    }
}
//停止定位
-(void)lt_stopLocation{
   
    if (self.permissionBD) {
        
        
        [self.locationManager stopUpdatingLocation];
    }
    else{
        
        if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
            
            [ltlocation lt_stopLocation];
        }
    }
}

#pragma mark getter 

-(BOOL)permissionBD{

    return permissionSucceed;
}

-(NSString *)detailAddress{
    
    if (self.permissionBD) {
        
        BMKLocationReGeocode * rgcData = self.currentLocation.rgcData;
        return [[NSString stringWithFormat:@"%@%@%@%@%@(%@)",rgcData.province,rgcData.city,rgcData.district,rgcData.street,rgcData.streetNumber,rgcData.locationDescribe] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation detailAddress];
    }
    return @"";
}
-(NSString *)briefAddress{

    if (self.permissionBD) {
        
        BMKLocationReGeocode * rgcData = self.currentLocation.rgcData;
        
        return [[NSString stringWithFormat:@"%@|%@|%@|",rgcData.province,rgcData.city,rgcData.district] stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation briefAddress];
    }
    return @"|||";
}
-(NSString *)city{
    
    if (self.permissionBD) {
        
        BMKLocationReGeocode * rgcData = self.currentLocation.rgcData;
        
        return [NSString stringWithFormat:@"%@",rgcData.city];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation city];
    }
    
    return @"";
}
-(NSString *)latitudeBaiDu{

    if (self.permissionBD) {
        
        CLLocationCoordinate2D location = self.currentLocation.location.coordinate;
        return [@(location.latitude) description];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation latitudeBaiDu];
    }
    return @"";
}
-(NSString *)longitudeBaiDu{
    
    if (self.permissionBD) {
        
        CLLocationCoordinate2D location = self.currentLocation.location.coordinate;
        return [@(location.longitude) description];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation longitudeBaiDu];
    }
    return @"";
}

-(BOOL)located{
    
    if ([self locateEnable]) {
        
        if ([self.latitudeBaiDu doubleValue] == 0.0 || [self.longitudeBaiDu doubleValue] == 0.0) {
            
            [self lt_startLocation];
            return NO;
        }
        else{
            
            return YES;
        }
    }
    else{
        
        return NO;
    }
}

-(BOOL)locateEnable{
    
    BOOL canLocated;
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        
        canLocated = [self locateEnableIOS8Later];
    }
    else{
        
        canLocated = [self locateEnableIOS8Before];
    }
    
    if (canLocated) {
        
        return YES;
    }
    else{
        
        [self didLocationServiceOff];
        return NO;
    }
}

- (void)didLocationServiceOff{
    
    NSLog(@"定位服务未开启");
    if (self.LocationDisableBlock) {
        
        self.LocationDisableBlock();
    }
}
//ios8之后
- (BOOL)locateEnableIOS8Later{
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        
        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
            
            //定位功能可用，开始定位
            
            return YES;
        }
    }
    
    return NO;
}
//ios8之前
- (BOOL)locateEnableIOS8Before{
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        
        //定位功能可用，开始定位
        
        return YES;
    }
#pragma clang diagnostic pop
    return NO;
}

#pragma mark BMKLocationManagerDelegate
/**
 *  @brief 当定位发生错误时，会调用代理的此方法。
 *  @param manager 定位 BMKLocationManager 类。
 *  @param error 返回的错误，参考 CLError 。
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager
          didFailWithError:(NSError * _Nullable)error{
    
    NSLog(@"定位失败:%@",error);
}

/**
 *  @brief 连续定位回调函数。
 *  @param manager 定位 BMKLocationManager 类。
 *  @param location 定位结果，参考BMKLocation。
 *  @param error 错误信息。
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager
         didUpdateLocation:(BMKLocation * _Nullable)location
                   orError:(NSError * _Nullable)error{
    
        self.currentLocation = location;
}

/**
 *  @brief 定位权限状态改变时回调函数
 *  @param manager 定位 BMKLocationManager 类。
 *  @param status 定位权限状态。
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    
    NSLog(@"定位权限状态改变:%@",@(status));
}

/**
 * @brief 该方法为BMKLocationManager提示需要设备校正回调方法。
 * @param manager 提供该定位结果的BMKLocationManager类的实例。
 */
- (BOOL)BMKLocationManagerShouldDisplayHeadingCalibration:(BMKLocationManager * _Nonnull)manager{
    
    NSLog(@"定位-提示需要设备校正");
    return YES;
}

/**
 * @brief 该方法为BMKLocationManager提供设备朝向的回调方法。
 * @param manager 提供该定位结果的BMKLocationManager类的实例
 * @param heading 设备的朝向结果
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager
          didUpdateHeading:(CLHeading * _Nullable)heading{
    
    NSLog(@"定位-设备朝向:%@",heading);
}

/**
 * @brief 该方法为BMKLocationManager所在App系统网络状态改变的回调事件。
 * @param manager 提供该定位结果的BMKLocationManager类的实例
 * @param state 当前网络状态
 * @param error 错误信息
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager
     didUpdateNetworkState:(BMKLocationNetworkState)state
                   orError:(NSError * _Nullable)error{
    
    NSLog(@"定位-系统网络状态改变:%@",@(state));
}

#pragma mark BMKLocationAuthDelegate
/**
 *@brief 返回授权验证错误
 *@param iError 错误号 : 为0时验证通过，具体参加BMKLocationAuthErrorCode
 */
- (void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError{
    
    switch (iError) {
        case BMKLocationAuthErrorSuccess:
            NSLog(@"BDMap启动正常");
            break;
        case BMKLocationAuthErrorNetworkFailed:
            NSLog(@"BDMap联网失败");
            break;
        case BMKLocationAuthErrorFailed:
            NSLog(@"BDMap-key非法");
            break;
        default:
            NSLog(@"BDMap-未知错误");
            break;
    }
    
    if (iError == BMKLocationAuthErrorSuccess) {
        NSLog(@"BDMap授权成功");
        permissionSucceed = YES;
        
        if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
            
            [ltlocation lt_stopLocation];
            ltlocation = nil;
        }
        
        [self lt_startLocation];
    }
    else {
//        NSLog(@"BDMap 授权失败:%d",iError);
        permissionSucceed = NO;
        
        ltlocation = [LTLocation sharedLocation];
        [self lt_startLocation];
    }
}

@end
