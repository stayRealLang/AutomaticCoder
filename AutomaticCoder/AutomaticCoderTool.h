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


+ (JsonValueType)getTypeByYApiTypeString:(NSString *)typeStr;


@end

NS_ASSUME_NONNULL_END
