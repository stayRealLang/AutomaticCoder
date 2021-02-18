//
//  NSDictionary+Json.h
//  AutomaticCoder
//
//  Created by 阿郎哥 on 2021/2/18.
//  Copyright © 2021 me.zhangxi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Json)

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

+ (NSString*)dictionaryToJson:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
