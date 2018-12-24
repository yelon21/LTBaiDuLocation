//
//  LTLocation.m
//  LocationTest
//
//  Created by yelon on 14-5-5.
//  Copyright (c) 2014年 yelon. All rights reserved.
//

#import "LTLocation.h"
#import "GTMBase64.h"
#import <UIKit/UIKit.h>

@interface LTLocation()<CLLocationManagerDelegate>{
    
    CLLocationManager *locationManager;
}

@property(nonatomic,strong,readwrite) NSString *city;

@property(nonatomic,strong,readwrite) CLPlacemark *currentPlacemark;

@property(nonatomic,strong,readwrite) NSString *latitudeBaiDu;//纬度
@property(nonatomic,strong,readwrite) NSString *longitudeBaiDu;//经度
@property(nonatomic,strong,readwrite) NSString *latitudeGPS;//GPS纬度
@property(nonatomic,strong,readwrite) NSString *longitudeGPS;//GPS经度
@property(nonatomic,strong,readwrite) NSString *briefAddress;//省|市|区|postalCode
@property(nonatomic,strong,readwrite) NSString *detailAddress;//详细地址
@end


@implementation LTLocation

+ (id)sharedLocation{
    
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        
        sharedInstance = [[LTLocation alloc] init];
    });
    return sharedInstance;
}

-(NSString *)debugDescription{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"latitudeBaiDu"] = self.latitudeBaiDu;
    dictionary[@"longitudeBaiDu"] = self.longitudeBaiDu;
    dictionary[@"latitudeGPS"] = self.latitudeGPS;
    dictionary[@"longitudeGPS"] = self.longitudeGPS;
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
/*
 精确度级别：
 kCLLocationAccuracyBestForNavigation
 kCLLocationAccuracyBest                //使用当前可用精确度最高的方法
 kCLLocationAccuracyNearestTenMeters    //10米
 kCLLocationAccuracyHundredMeters       //100米
 kCLLocationAccuracyKilometer           //1000米
 kCLLocationAccuracyThreeKilometers     //3000米
 double类型，可以自定义
 */

-(id)init{

    if ([super init]) {

        self.latitudeGPS = @"0.0";
        self.longitudeGPS = @"0.0";
        
        self.latitudeBaiDu = @"0.0";
        self.longitudeBaiDu = @"0.0";
        
        self.detailAddress = @"";
        self.briefAddress = @"|||";
        
        self.city = @"";
        
        locationManager = [[CLLocationManager alloc]init];
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            
            [locationManager requestWhenInUseAuthorization];
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        locationManager.distanceFilter = 10.0;
        
    }
    
    return self;
}

//开始定位
-(void)lt_startLocation{

    [locationManager startUpdatingLocation];
}
//停止定位
-(void)lt_stopLocation{

    [locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    if ([locations count]>0) {
        
        CLLocation *location = [locations objectAtIndex:0];
        [self didGetNewLocation:location];
    }
}

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation
          fromLocation:(CLLocation *)oldLocation{
    
    [self didGetNewLocation:newLocation];
}

- (void)didGetNewLocation:(CLLocation *)location{
    
    CLLocation *newLocation = location;//[LTLocation transformToMars:location];
    
    //GPS
    self.longitudeGPS = [NSString stringWithFormat:@"%@",@(newLocation.coordinate.longitude)];
    self.latitudeGPS = [NSString stringWithFormat:@"%@",@(newLocation.coordinate.latitude)];
    
    self.longitudeBaiDu = [self.longitudeGPS copy];
    self.latitudeBaiDu = [self.latitudeGPS copy];
    //转百度
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CLLocationCoordinate2D newCoordinate2D = newLocation.coordinate;
        
        NSString *apiUrl = [NSString stringWithFormat:@"https://api.map.baidu.com/ag/coord/convert?from=0&to=4&x=%@&y=%@",@(newCoordinate2D.longitude),@(newCoordinate2D.latitude)];

        NSString *jsonString = [[NSString alloc]initWithContentsOfURL:[NSURL URLWithString:apiUrl]
                                                             encoding:NSUTF8StringEncoding
                                                                error:nil];
        if (!jsonString) {
            
            return ;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:NSJSONReadingMutableContainers error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (dic) {
                
                if ([dic[@"error"] integerValue] == 0) {
                    
                    NSString *xEnc = dic[@"x"];
                    NSString *yEnc = dic[@"y"];
                    
                    
                    self.longitudeBaiDu = [[NSString alloc]initWithData:[GTMBase64 decodeString:xEnc] encoding:NSUTF8StringEncoding];
                    self.latitudeBaiDu = [[NSString alloc]initWithData:[GTMBase64 decodeString:yEnc] encoding:NSUTF8StringEncoding];
                }
            }
            NSLog(@"longitudeStr == %@,%@",self->_latitudeBaiDu,self->_longitudeBaiDu);
        });
    });
    
    
    
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    [geocoder reverseGeocodeLocation:newLocation
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       
//                       [self showPlaceMarks:placemarks];
  
                       if ([placemarks count]>0) {
                           
                           CLPlacemark *placemark = [placemarks lastObject];
                           self.currentPlacemark = placemark;
                           
                           NSString *detailAddress = nil;
                           
                           if ([placemark.name length]>0){
                               
                               NSLog(@"name=%@",placemark.name);
                               detailAddress = placemark.name;
                           }
                           else {
                               
                               NSArray *addressLines = [placemark.addressDictionary objectForKey:@"FormattedAddressLines"];
                               
                               if ([addressLines count]>0){
                               
                                   detailAddress = [addressLines lastObject];
                               }
                           }
    
                           if ([detailAddress hasPrefix:@"中国"]) {
                               
                               detailAddress = [detailAddress substringFromIndex:2];
                           }
                           self.detailAddress = detailAddress;
                           
                           if (self.detailAddress) {
                               [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLocation" object:nil];
                           }
                           
                           NSString *state = [self.currentPlacemark.addressDictionary objectForKey:@"State"];
                           NSString *city  = [self.currentPlacemark.addressDictionary objectForKey:@"City"];
                           NSString *subCity = self.currentPlacemark.subLocality;
                           NSString *code  = self.currentPlacemark.postalCode;
                           
                           if (!city) {
                               
                               city = @"";
                           }
                           if (!state) {
                               
                               state = city;
                           }
                           if (!subCity) {
                               
                               subCity = @"";
                           }
                           if (!code) {
                               
                               code = @"";
                           }

                           self.briefAddress = [NSString stringWithFormat:@"%@|%@|%@|%@",state,city,subCity,code];
                           
                           if (city==nil||[city isEqualToString:@""]) {
                               
                               self.city = state;
                           }
                           else{
                               
                               self.city = city;
                           }
                           
                           if (state==nil||[state isEqualToString:@""]) {
                               
                               state = city;
                           }
                       }
                   }];
}

- (void)locationManager: (CLLocationManager *)manager
       didFailWithError: (NSError *)error {
    
    //    NSString *errorString = @"";
    
    NSLog(@"Error: %@",[error localizedDescription]);
    switch([error code]) {
        case kCLErrorDenied:
        {
            
            [self didLocationServiceOff];
        };
            break;
        case kCLErrorLocationUnknown:
            //Probably temporary...
            //            errorString = @"位置服务不可用!";
            break;
        default:
            //            errorString = @"定位发生错误!";
            break;
    }
}

- (void)didLocationServiceOff{
    
    NSLog(@"定位服务未开启");
    if (self.LocationDisableBlock) {
        
        self.LocationDisableBlock();
    }
}

-(BOOL)located{
    
    if ([self locateEnable]) {
        
        if ([self.latitudeGPS doubleValue] == 0.0 || [self.longitudeGPS doubleValue] == 0.0) {
            
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

const double a = 6378245.0;
const double ee = 0.00669342162296594323;

+ (CLLocation *)transformToMars:(CLLocation *)location {
    //是否在中国大陆之外
    if ([[self class] outOfChina:location]) {
        return location;
    }
    double dLat = [[self class] transformLatWithX:location.coordinate.longitude - 105.0 y:location.coordinate.latitude - 35.0];
    double dLon = [[self class] transformLonWithX:location.coordinate.longitude - 105.0 y:location.coordinate.latitude - 35.0];
    double radLat = location.coordinate.latitude / 180.0 * M_PI;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * M_PI);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * M_PI);
    return [[CLLocation alloc] initWithLatitude:location.coordinate.latitude + dLat longitude:location.coordinate.longitude + dLon];
}

+ (BOOL)outOfChina:(CLLocation *)location {
    if (location.coordinate.longitude < 72.004 || location.coordinate.longitude > 137.8347) {
        return YES;
    }
    if (location.coordinate.latitude < 0.8293 || location.coordinate.latitude > 55.8271) {
        return YES;
    }
    return NO;
}

+ (double)transformLatWithX:(double)x y:(double)y {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

+ (double)transformLonWithX:(double)x y:(double)y {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

- (void)showPlaceMarks:(NSArray *)placemarks{
    
    for (CLPlacemark *placeMark in placemarks) {
        NSLog(@"==============================");
        NSLog(@"name=%@",placeMark.name);
        NSLog(@"thoroughfare=%@",placeMark.thoroughfare);
        
        NSLog(@"subThoroughfare=%@",placeMark.subThoroughfare);
        NSLog(@"locality=%@",placeMark.locality);
        NSLog(@"subLocality=%@",placeMark.subLocality);
        
        NSLog(@"administrativeArea=%@",placeMark.administrativeArea);
        NSLog(@"subAdministrativeArea=%@",placeMark.subAdministrativeArea);
        NSLog(@"postalCode=%@",placeMark.postalCode);
        
        NSLog(@"ISOcountryCode=%@",placeMark.ISOcountryCode);
        NSLog(@"country=%@",placeMark.country);
        
        NSDictionary *addressDic = placeMark.addressDictionary;
        
        NSArray *keyArray = [addressDic allKeys];
        
        for (NSString *key in keyArray) {
            
            if ([[addressDic objectForKey:key] isKindOfClass:[NSArray class]]) {
                NSLog(@"%@ == %@",key,[[addressDic objectForKey:key] objectAtIndex:0]);
            }
            else{
                NSLog(@"%@ == %@",key,[addressDic objectForKey:key]);
            }
        }
    }
}

-(void)dealloc{
    
    if (locationManager) {
        
        [self lt_stopLocation];
    }
}
@end
