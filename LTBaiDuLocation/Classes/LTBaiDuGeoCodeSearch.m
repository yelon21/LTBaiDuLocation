//
//  LTBaiDuGeoCodeSearch.m
//  Pods
//
//  Created by yelon on 16/10/17.
//
//

#import "LTBaiDuGeoCodeSearch.h"

@interface LTBaiDuGeoCodeSearch ()<BMKGeoCodeSearchDelegate>{
    
    BMKGeoCodeSearch* _geocodesearch;
}

@property(nonatomic,strong) GeoCodeSearchBlock geoCodeSearchBlock;
@property(nonatomic,strong) ReverseGeoCodeSearchBlock reverseGeoCodeSearchBlock;
@end


@implementation LTBaiDuGeoCodeSearch

-(id)init{
    
    if (self = [super init]) {
        
        _geocodesearch = [[BMKGeoCodeSearch alloc]init];
        _geocodesearch.delegate = self;
    }
    
    return self;
}

//地理编码
-(BOOL)lt_startGeocode:(NSString *)city
               address:(NSString *)address
           resultBlock:(GeoCodeSearchBlock)geoCodeSearchBlock{
    
    self.geoCodeSearchBlock = geoCodeSearchBlock;
    
    BMKGeoCodeSearchOption *geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc]init];
    geoCodeSearchOption.city = city;
    geoCodeSearchOption.address = address;
    BOOL flag = [_geocodesearch geoCode:geoCodeSearchOption];
    
    if(flag){
        NSLog(@"反geo检索发送成功");
    }
    else{
        NSLog(@"反geo检索发送失败");
    }
    return flag;
}
//反向地理编码
-(BOOL)lt_startReverseGeocode:(CLLocationCoordinate2D)pt
                  resultBlock:(ReverseGeoCodeSearchBlock)reverseGeoCodeSearchBlock{
    
    self.reverseGeoCodeSearchBlock = reverseGeoCodeSearchBlock;
    
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
    
    if (self.geoCodeSearchBlock) {
        
        if (BMK_SEARCH_NO_ERROR == error) {
            
            self.geoCodeSearchBlock(result);
        }
    }
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
    
    if (self.reverseGeoCodeSearchBlock) {
        
        if (BMK_SEARCH_NO_ERROR == error) {
            
            self.reverseGeoCodeSearchBlock(result);
        }
    }
}
@end
