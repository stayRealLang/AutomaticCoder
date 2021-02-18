//
//  AutomaticCoderTool.m
//  AutomaticCoder
//
//  Created by 阿郎哥 on 2021/2/18.
//  Copyright © 2021 me.zhangxi. All rights reserved.
//

#import "AutomaticCoderTool.h"

@implementation AutomaticCoderTool


+ (JsonValueType)getTypeByYApiTypeString:(NSString *)typeStr {
//    boolean
//    number
//    integer
//    string
//    object
//    array
    if ([@"boolean" isEqualToString:typeStr]) return kBool;
    else if([@"number" isEqualToString:typeStr]) return kNumber;
    else if([@"integer" isEqualToString:typeStr]) return kNumber;
    else if([@"object" isEqualToString:typeStr]) return kDictionary;
    else if([@"array" isEqualToString:typeStr]) return kArray;
    
    return kString;
}

@end
