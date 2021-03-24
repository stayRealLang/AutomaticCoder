//
//  YApiToCodeFileController.m
//  AutomaticCoder
//
//  Created by 阿郎哥 on 2021/2/17.
//  Copyright © 2021 me.zhangxi. All rights reserved.
//

#import "YApiToCodeFileController.h"
#import "NSDictionary+Json.h"

@interface YApiToCodeFileController ()<NSTableViewDelegate,NSTableViewDataSource>

@property (weak) IBOutlet NSScrollView *dataScrollView;
@property (weak) IBOutlet NSTableView *tableView;

@property(nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation YApiToCodeFileController

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

#pragma mark - Actions
//获取json文件
- (IBAction)getJSONFile:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.canChooseFiles = YES;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {

        if(result == 0) return ;
        NSString *path = [panel.URL path];
        NSData *jsonData = [[NSData alloc] initWithContentsOfFile:path];
        NSError *error;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (!jsonData || error) {
            //DLog(@"JSON解码失败");
        } else {
            self.dataArray = [NSMutableArray arrayWithArray:jsonObj];
            [_tableView reloadData];
        }

    }];
}

//创建代码文件
- (IBAction)createCodeFile:(NSButton *)sender {
    NSInteger selectIndex = _tableView.selectedRowIndexes.firstIndex;
    NSDictionary *sectionDic = _dataArray[selectIndex];
    NSLog(@"%@",sectionDic[@"name"]);
    [self anlysJson:sectionDic];
    
}

//解析json，获取需要的字段
- (void)anlysJson:(NSDictionary *)sectionDic {
    NSString *sectionName = sectionDic[@"name"];
    NSLog(@"sectionName:%@",sectionName);
    NSArray *sectionList = sectionDic[@"list"];
    for (NSDictionary *requestDic in sectionList) {
        NSString *requestTitle = requestDic[@"title"];//医院列表
        NSString *itemId = requestDic[@"_id"];//请求id
        NSString *requestType = requestDic[@"method"];//POST
        NSString *path = requestDic[@"path"];///consultations/order/listHospital
//            (
//                        {
//                    "_id" = 6020cdf338e4b133f9593643;
//                    name = "Content-Type";
//                    required = 1;
//                    value = "application/json";
//                }
//            )
        NSArray *req_headers = requestDic[@"req_headers"];
        NSString *req_body_other = requestDic[@"req_body_other"];//请求参数
        NSString *res_body = requestDic[@"res_body"];//返回参数
        NSString *markdown = requestDic[@"markdown"];//对接负责人：李昆杰
        
        NSDictionary *requestDic = [NSDictionary dictionaryWithJsonString:req_body_other];
        NSDictionary *responseDic = [NSDictionary dictionaryWithJsonString:res_body];
        NSArray *pathArr = [path componentsSeparatedByString:@"/"];
        NSMutableString *name = [NSMutableString string];
        if (pathArr.count >= 2) {
            NSString *last2Words = pathArr[pathArr.count-2];
            
            [name appendString:[last2Words capitalizedString]];
        }
        if (pathArr.count >= 1) {
            NSString *lastWords = pathArr[pathArr.count-1];
            [name appendString:[lastWords capitalizedString]];
        }
        if (name.length > 0) {
            [self createModelFileWithResponseDic:responseDic name:name];
        }else{
            NSLog(@"path url有问题");
        }
        
    }
}

- (void)createModelFileWithResponseDic:(NSDictionary *)responseDic name:(NSString *)name{
    if (responseDic == nil || ![responseDic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *data = responseDic[@"properties"][@"data"];
    NSDictionary *dataPro = data[@"properties"];
    if (dataPro.allKeys.count <= 0) {
        return;
    }
    if (dataPro.allKeys.count == 1 && [dataPro.allKeys containsObject:@"list"]) {
        //列表数据
        NSDictionary *itemsDic = dataPro[@"list"][@"items"];
        NSString *fileName = [NSString stringWithFormat:@"DSL%@ListModel",name];
        [self generateClass:fileName forDic:itemsDic];
//        for (NSString *keyStr in itemsDic.allKeys) {
//            NSDictionary *itemDic = itemsDic[keyStr];
//            NSString *typeStr = itemDic[@"type"];
//            NSString *description = itemDic[@"description"];
//
//            NSLog(@"keyStr:%@  typeStr:%@  description:%@",keyStr,typeStr,description);
//        }
    }else{
        //
        NSString *fileName = [NSString stringWithFormat:@"DSL%@Model",name];
        [self generateClass:name forDic:data];
//        for (NSString *keyStr in dataPro.allKeys) {
//            NSDictionary *itemDic = dataPro[keyStr];
//            NSString *typeStr = itemDic[@"type"];
//            NSString *description = itemDic[@"description"];
//
//            NSLog(@"keyStr:%@  typeStr:%@  description:%@",keyStr,typeStr,description);
//        }
    }
}
-(void)createClass:(NSString *)name forDic:(NSDictionary *)json {
    //yapi定义的类型object、array等
    NSString *typeStr = json[@"type"];
    JsonValueType type = [AutomaticCoderTool getTypeByYApiTypeString:typeStr];
    //备注
    NSString *description = json[@"description"];
    //属性
    NSDictionary *properties = json[@"properties"];
    switch (type) {
        case kDictionary:
        {
            //准备模板
            NSMutableString *templateH = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"zx1"] encoding:NSUTF8StringEncoding error:nil];
            NSMutableString *templateM = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"zx2"] encoding:NSUTF8StringEncoding error:nil];

            //.h
            //name
            //property
            NSMutableString *proterty = [NSMutableString string];
            NSMutableString *import = [NSMutableString string];
            
            for (NSString *subKey in properties.allKeys) {
                //key   merchantExt
                //valueDic    {"type":"object","properties":{...}}
                NSDictionary *subValueDic = properties[subKey];
                NSString *subTypeStr = subValueDic[@"type"];
                JsonValueType subType = [AutomaticCoderTool getTypeByYApiTypeString:subTypeStr];
                [proterty appendFormat:@"@property (nonatomic,strong) %@Entity *%@;///<%@\n",[name capitalizedString] , name, description?:@"无"];
                [import appendFormat:@"#import \"%@Entity.h\"",[name capitalizedString]];
                
            }
            
            [self generateClass:[NSString stringWithFormat:@"%@Entity",[name capitalizedString]] forDic:value];
        }
            break;
            
        default:
            break;
    }
}

-(void)generateClass:(NSString *)name forDic:(NSDictionary *)json {
    //准备模板
    
    NSMutableString *templateH = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"zx1"] encoding:NSUTF8StringEncoding error:nil];
    NSMutableString *templateM = [[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"zx2"] encoding:NSUTF8StringEncoding error:nil];

    //.h
    //name
    //property
    NSMutableString *proterty = [NSMutableString string];
    NSMutableString *import = [NSMutableString string];
    //.m
    //MJ属性是数组，数组元素为也是模型
    NSMutableString *propertyArrayStr = [NSMutableString string];
    
    //yapi定义的类型object、array等
    NSString *typeStr = json[@"type"];
    //备注
    NSString *description = json[@"description"];
    //属性
    NSDictionary *properties = json[@"properties"];
    for (NSString *key in properties.allKeys) {
        //key  merchantExt
        NSDictionary *valueDic = properties[key];
        JsonValueType type = [AutomaticCoderTool getTypeByYApiTypeString:typeStr];
        NSString *typeName = [AutomaticCoderTool typeNameWithType:type];
        id value;
        switch (type) {
            case kString:
                
                [proterty appendFormat:@"@property (nonatomic,copy) %@ *%@;///<%@\n",typeName, name, description?:@"无"];
                break;
            case kNumber:
                [proterty appendFormat:@"@property (nonatomic,strong) %@ *%@;///<%@\n",typeName , name, description?:@"无"];
                break;
            case kArray:
            {
                value = json[@"items"];
                [proterty appendFormat:@"@property (nonatomic,strong) NSMutableArray *%@;///<%@\n" , name, description?:@"无"];
                [import appendFormat:@"#import \"%@Entity.h\"",[name capitalizedString]];
                [self generateClass:[NSString stringWithFormat:@"%@Entity",[name capitalizedString]] forDic:value];
            }
                break;
            case kDictionary:
                value = json[@"properties"];
                [proterty appendFormat:@"@property (nonatomic,strong) %@Entity *%@;///<%@\n",[name capitalizedString] , name, description?:@"无"];
                [import appendFormat:@"#import \"%@Entity.h\"",[name capitalizedString]];
                [self generateClass:[NSString stringWithFormat:@"%@Entity",[name capitalizedString]] forDic:value];

                break;
            case kBool:
                [proterty appendFormat:@"@property (nonatomic,assign) %@ %@;///<%@\n",typeName , name, description?:@"无"];
                break;
            default:
                break;
        }
    }
    

    [templateH replaceOccurrencesOfString:@"#name#"
                               withString:name
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateH.length)];
    [templateH replaceOccurrencesOfString:@"#import#"
                               withString:import
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateH.length)];
    [templateH replaceOccurrencesOfString:@"#property#"
                               withString:proterty
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateH.length)];

    //.m
    //NSCoding
    //name
    [templateM replaceOccurrencesOfString:@"#name#"
                               withString:name
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateM.length)];


    NSMutableString *config = [NSMutableString string];
    NSMutableString *encode = [NSMutableString string];
    NSMutableString *decode = [NSMutableString string];
    NSMutableString *description = [NSMutableString string];

    NSDictionary *list =  @{
                            @"property:array":propertyArrayStr,
                            @"config":config,
                            @"encode":encode,
                            @"decode":decode,
                            @"description":description
                            };


    for(NSString *key in [json allKeys])
    {
        JsonValueType type = [AutomaticCoderTool getTypeByYApiTypeString:value];
        switch (type) {
            case kString:
            case kNumber:
                [config appendFormat:@"self.%@%@  = [json objectForKey:@\"\"];\n\t\t" ,key,key];
                [encode appendFormat:@"[aCoder encodeObject:self.%@ forKey:@\"zx_%@\"];\n\t" ,key,key];
                [decode appendFormat:@"self.%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n\t\t" ,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : %%@\\n\",self.%@];\n\t" ,key ,key];
                break;
            case kArray:
            {
                if([self isDataArray:value])
                {
                    [propertyArrayStr appendFormat:@"@\"%@%@\":@\"%@Entity\"," ,key,[self uppercaseFirstChar:key]];
                    [config appendFormat:@"self.%@ = [NSMutableArray array];\n\t" ,key];
                    [config appendFormat:@"for(NSDictionary *item in [json objectForKey:@\"%@\"])\n\t\t",key];
                    [config appendString:@"{\n"];
                    [config appendFormat:@"[self.%@%@ addObject:[[%@Entity alloc] initWithJson:item]];\n\t" ,key,[self uppercaseFirstChar:key]];
                    [config appendString:@"}\n"];
                    [encode appendFormat:@"[aCoder encodeObject:self.%@ forKey:@\"zx_%@\"];\n\t" ,key,key];
                    [decode appendFormat:@"self.%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n\t\t" ,key,key];
                   [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@ : \\n\",self.%@];\n\t" ,key ,key];
                }
            }
                break;
            case kDictionary:
                [config appendFormat:@"self.%@%@  = [[%@Entity alloc] initWithJson:[json objectForKey:@\"%@\"]];\n\t\t" ,key,[self uppercaseFirstChar:key],key];
                [encode appendFormat:@"[aCoder encodeObject:self.%@%@ forKey:@\"zx_%@\"];\n\t" ,key,key];
                [decode appendFormat:@"self.%@%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n\t\t" ,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@%@ : %%@\\n\",self.%@%@];\n\t" ,key ,key];

                break;
            case kBool:
                [config appendFormat:@"self.%@%@ = [[json objectForKey:@\"%@\"]boolValue];\n\t\t" ,key,key];
                [encode appendFormat:@"[aCoder encodeBool:self.%@%@ forKey:@\"zx_%@\"];\n\t" ,key,key];
                [decode appendFormat:@"self.%@%@ = [aDecoder decodeBoolForKey:@\"zx_%@\"];\n\t" ,key,key];
                [description appendFormat:@"result = [result stringByAppendingFormat:@\"%@%@ : %%@\\n\",self.%@%@?@\"yes\":@\"no\"];\n\t" ,key ,key];
                break;
            default:
                break;
        }
    }

    //修改模板
    for(NSString *key in [list allKeys])
    {
        [templateM replaceOccurrencesOfString:[NSString stringWithFormat:@"#%@#",key]
                                   withString:[list objectForKey:key]
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, templateM.length)];
    }


    //写文件
    NSLog(@"%@",[NSString stringWithFormat:@"%@/%@.h",path,name]);
    [templateH writeToFile:[NSString stringWithFormat:@"%@/%@.h",path,name]
                atomically:NO
                  encoding:NSUTF8StringEncoding
                     error:nil];
    [templateM writeToFile:[NSString stringWithFormat:@"%@/%@.m",path,name]
                atomically:NO
                  encoding:NSUTF8StringEncoding
                     error:nil];


}


-(JsonValueType)type:(NSDictionary *)obj {
    NSString *type = obj[@"type"];
    if ([@"string" isEqualToString:type]) {
        return kString;
    }else if ([@"number" isEqualToString:type]) {
        return kNumber;
    }else if ([@"array" isEqualToString:type]) {
        return kArray;
    }else if ([@"object" isEqualToString:type]) {
        return kDictionary;
    }
}

#pragma mark - TableView Delegate
 -(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
     return _dataArray.count;
 }

 -(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
     NSDictionary *sectionDic = _dataArray[row];
     return sectionDic[@"name"];
 }

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn{
    NSLog(@"didClickTableColumn");
}
#pragma mark - Getter
- (NSMutableArray *)dataArray{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

@end
