//
//  LTBaiDuGeoCodeSearch.h
//  Pods
//
//  Created by yelon on 16/10/17.
//
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>

typedef void(^GeoCodeSearchBlock)(BMKGeoCodeResult *result);
typedef void(^ReverseGeoCodeSearchBlock)(BMKReverseGeoCodeResult *result);

@interface LTBaiDuGeoCodeSearch : NSObject

//地理编码
-(BOOL)lt_startGeocode:(NSString *)city
               address:(NSString *)address
           resultBlock:(GeoCodeSearchBlock)geoCodeSearchBlock;
//反向地理编码
-(BOOL)lt_startReverseGeocode:(CLLocationCoordinate2D)pt
                  resultBlock:(ReverseGeoCodeSearchBlock)reverseGeoCodeSearchBlock;

@end
