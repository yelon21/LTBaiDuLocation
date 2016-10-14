//
//  LTBaiDuLocation.m
//  LTBaiDuLocation
//
//  Created by yelon on 16/10/14.
//  Copyright © 2016年 yjpal. All rights reserved.
//

#import "LTBaiDuLocation.h"
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>

@interface LTBaiDuLocation ()<BMKLocationServiceDelegate,BMKGeoCodeSearchDelegate,BMKGeneralDelegate>{

    BMKMapManager* _mapManager;
    BMKLocationService* _locService;
    BMKGeoCodeSearch* _geocodesearch;
    
    BOOL startSucceed;
    BOOL networkSucceed;
    BOOL permissionSucceed;
}

@property(nonatomic,strong) BMKReverseGeoCodeResult *reverseGeoCodeResult;

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
        networkSucceed = NO;
        permissionSucceed = NO;
        
        self.detailAddress = @"";
        
        _mapManager = [[BMKMapManager alloc]init];
        _locService = [[BMKLocationService alloc]init];
        
        _locService.desiredAccuracy = kCLLocationAccuracyBest;
        _locService.distanceFilter = 10.0;
        
        _geocodesearch = [[BMKGeoCodeSearch alloc]init];
        _geocodesearch.delegate = self;
    }
    
    return self;
}

- (BOOL)lt_startWithBaiDuKey:(NSString *)key{

    if (!key || ![key isKindOfClass:[NSString class]]||[key length]==0) {
        
        return NO;
    }
    
    startSucceed = [_mapManager start:key generalDelegate:self];
    if (!startSucceed) {
        NSLog(@"manager start failed!");
    }
    return startSucceed;
}

//开始定位
-(void)lt_startLocation{

    if (!startSucceed ||!permissionSucceed || !networkSucceed) {
        
        return;
    }
    _locService.delegate = self;
    [_locService startUserLocationService];
}
//停止定位
-(void)lt_stopLocation{
   
    _locService.delegate = nil;
    [_locService stopUserLocationService];
}
//反向地理编码
-(BOOL)lt_startReverseGeocode:(CLLocationCoordinate2D)pt{
    
    BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc]init];
    reverseGeocodeSearchOption.reverseGeoPoint = pt;
    BOOL flag = [_geocodesearch reverseGeoCode:reverseGeocodeSearchOption];
    
    if(flag){
        NSLog(@"反geo检索发送成功");
    }
    else{
        NSLog(@"反geo检索发送失败");
    }
    return flag;
}

#pragma mark getter 
-(NSString *)detailAddress{
    
    return [NSString stringWithFormat:@"%@",self.reverseGeoCodeResult.address];
}
-(NSString *)briefAddress{

    BMKAddressComponent *component = self.reverseGeoCodeResult.addressDetail;
    
    return [NSString stringWithFormat:@"%@|%@|%@|",component.province,component.city,component.district];
}
-(NSString *)city{

    BMKAddressComponent *component = self.reverseGeoCodeResult.addressDetail;
    
    return [NSString stringWithFormat:@"%@",component.city];
}
-(NSString *)latitudeBaiDu{

    CLLocationCoordinate2D location = self.reverseGeoCodeResult.location;
    return [@(location.latitude) description];
}
-(NSString *)longitudeBaiDu{
    
    CLLocationCoordinate2D location = self.reverseGeoCodeResult.location;
    return [@(location.longitude) description];
}

-(BOOL)located{
    
    if ([self locateEnable]) {
        
        if ([self.latitudeBaiDu doubleValue] == 0.0 || [self.longitudeBaiDu doubleValue] == 0.0) {
            
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

- (BOOL)locateEnableIOS8Later{
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        
        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
            
            //定位功能可用，开始定位
            
            return YES;
        }
    }
    
    return NO;
}

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

#pragma mark BMKGeoCodeSearchDelegate
/**
 *返回地址信息搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结BMKGeoCodeSearch果
 *@param error 错误号，@see BMKSearchErrorCode
 */
- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher
                    result:(BMKGeoCodeResult *)result
                 errorCode:(BMKSearchErrorCode)error{
    
}
/**
 *返回反地理编码搜索结果
 *@param searcher 搜索对象
 *@param result 搜索结果
 *@param error 错误号，@see BMKSearchErrorCode
 */
-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher
                           result:(BMKReverseGeoCodeResult *)result
                        errorCode:(BMKSearchErrorCode)error{
    
    if (BMK_SEARCH_NO_ERROR == error) {
        
        self.reverseGeoCodeResult = result;
    }
}

#pragma mark BMKLocationServiceDelegate
/**
 *在地图View将要启动定位时，会调用此函数
 *@param mapView 地图View
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
    
    [self lt_startReverseGeocode:userLocation.location.coordinate];
    
}

/**
 *在地图View停止定位后，会调用此函数
 *@param mapView 地图View
 */
- (void)didStopLocatingUser{
    
    NSLog(@"stop locate");
}

/**
 *定位失败后，会调用此函数
 *@param mapView 地图View
 *@param error 错误号，参考CLError.h中定义的错误号
 */
- (void)didFailToLocateUserWithError:(NSError *)error{
   
    NSLog(@"location error");
}
#pragma mark BMKGeneralDelegate
- (void)onGetNetworkState:(int)iError{
    
    if (0 == iError) {
        NSLog(@"联网成功");
        networkSucceed = YES;
    }
    else{
        NSLog(@"onGetNetworkState %d",iError);
        networkSucceed = NO;
    }
}

- (void)onGetPermissionState:(int)iError{
   
    if (0 == iError) {
        NSLog(@"授权成功");
        permissionSucceed = YES;
    }
    else {
        NSLog(@"onGetPermissionState %d",iError);
        permissionSucceed = NO;
    }
}

@end
