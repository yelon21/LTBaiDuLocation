//
//  LTBaiDuLocation.m
//  LTBaiDuLocation
//
//  Created by yelon on 16/10/14.
//  Copyright © 2016年 yjpal. All rights reserved.
//

#import "LTBaiDuLocation.h"

#import "LTLocation.h"

@interface LTBaiDuLocation ()<BMKLocationServiceDelegate,BMKGeneralDelegate>{

    BMKMapManager* _mapManager;
    BMKLocationService* _locService;
    LTBaiDuGeoCodeSearch *search;
    BOOL startSucceed;
    BOOL permissionSucceed;
    
    LTLocation *ltlocation;
}

@property(nonatomic,strong,readwrite) BMKReverseGeoCodeResult *reverseGeoCodeResult;
@property(nonatomic,strong,readwrite) BMKUserLocation *currentLocation;

@property(nonatomic,assign,readwrite) NSString *detailAddress;//详细地址

@end


@implementation LTBaiDuLocation

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
        
        startSucceed = NO;
        permissionSucceed = NO;
        
        _mapManager = [[BMKMapManager alloc]init];
        _locService = [[BMKLocationService alloc]init];
        search = [[LTBaiDuGeoCodeSearch alloc]init];
        
        _locService.desiredAccuracy = kCLLocationAccuracyBest;
        _locService.distanceFilter = 10.0;
    }
    
    return self;
}

- (BOOL)lt_startWithBaiDuKey:(NSString *)key{

    if (!key || ![key isKindOfClass:[NSString class]]||[key length]==0) {
        
        NSLog(@"百度定位Key异常：%@",key);
        return NO;
    }
    
    startSucceed = [_mapManager start:key generalDelegate:self];
    if (!startSucceed) {
        NSLog(@"百度定位引擎启动失败：%@",key);
    }
    return startSucceed;
}

//开始定位
-(void)lt_startLocation{

    if (startSucceed && permissionSucceed) {
        
        _locService.delegate = self;
        [_locService startUserLocationService];
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
        
        _locService.delegate = nil;
        [_locService stopUserLocationService];
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
        
        return [NSString stringWithFormat:@"%@",self.reverseGeoCodeResult.address];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation detailAddress];
    }
    return @"";
}
-(NSString *)briefAddress{

    if (self.permissionBD) {
        
        BMKAddressComponent *component = self.reverseGeoCodeResult.addressDetail;
        
        return [NSString stringWithFormat:@"%@|%@|%@|",component.province,component.city,component.district];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation briefAddress];
    }
    return @"";
}
-(NSString *)city{
    
    if (self.permissionBD) {
        
        BMKAddressComponent *component = self.reverseGeoCodeResult.addressDetail;
        
        return [NSString stringWithFormat:@"%@",component.city];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation city];
    }
    
    return @"";
}
-(NSString *)latitudeBaiDu{

    if (self.permissionBD) {
        
        CLLocationCoordinate2D location = self.reverseGeoCodeResult.location;
        return [@(location.latitude) description];
    }
    else if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
        
        return [ltlocation latitudeBaiDu];
    }
    return @"";
}
-(NSString *)longitudeBaiDu{
    
    if (self.permissionBD) {
        
        CLLocationCoordinate2D location = self.reverseGeoCodeResult.location;
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

#pragma mark BMKLocationServiceDelegate
/**
 *在将要启动定位时，会调用此函数
 */
- (void)willStartLocatingUser{
    
    NSLog(@"start locate");
}

/**
 *用户方向更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation{
    
//    NSLog(@"heading is %@",userLocation.heading);
}

/**
 *用户位置更新后，会调用此函数
 *@param userLocation 新的用户位置
 */
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{

    NSLog(@"title=%@",userLocation.title);
    NSLog(@"subtitle=%@",userLocation.subtitle);

    self.currentLocation = userLocation;
    
    [search lt_startReverseGeocode:self.currentLocation.location.coordinate
                       resultBlock:^(BMKReverseGeoCodeResult *result) {
                           
                           self.reverseGeoCodeResult = result;
                       }];
}

/**
 *在停止定位后，会调用此函数
 */
- (void)didStopLocatingUser{
    
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param error 错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error{
   
    NSLog(@"location error");
}
#pragma mark BMKGeneralDelegate
- (void)onGetNetworkState:(int)iError{
    
    if (0 == iError) {
        NSLog(@"BDMap联网成功");
    }
    else{
        NSLog(@"BDMap联网失败-onGetNetworkState:%d",iError);
    }
}

- (void)onGetPermissionState:(int)iError{
   
    if (0 == iError) {
        NSLog(@"BDMap授权成功");
        permissionSucceed = YES;
        
        if (ltlocation && [ltlocation isKindOfClass:[LTLocation class]]) {
            
            [ltlocation lt_stopLocation];
            ltlocation = nil;
        }
        
        [self lt_startLocation];
    }
    else {
        NSLog(@"BDMapon授权失败:%d",iError);
        permissionSucceed = NO;
        
        ltlocation = [LTLocation sharedLocation];
        [self lt_startLocation];
    }
}

@end
