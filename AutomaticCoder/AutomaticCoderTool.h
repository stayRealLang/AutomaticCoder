//
//  AutomaticCoderTool.h
//  AutomaticCoder
//
//  Created by 阿郎哥 on 2021/2/18.
//  Copyright © 2021 me.zhangxi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum
{
    kString = 0,
    kNumber = 1,
    kArray  = 2,
    kDictionary = 3,
    kBool   = 4,
}JsonValueType;

@interface AutomaticCoderTool : NSObject


/// YApi根据type字符串获取类型
/// @param typeStr type字符串
+ (JsonValueType)getTypeByYApiTypeString:(NSString *)typeStr;


/// 根据类型获取类型名称，如NSString等
/// @param type JsonValueType类型
+ (NSString *)typeNameWithType:(JsonValueType)type;

@end

NS_ASSUME_NONNULL_END
