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
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        for (NSDictionary *requestDic in sectionList) {
            NSString *requestTitle = requestDic[@"title"];//医院列表
            NSString *itemId = requestDic[@"_id"];//请求id
            NSString *requestType = requestDic[@"method"];//POST
            NSString *path = requestDic[@"path"];///consultations/order/listHospital
            
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
                if(result == 0) return ;
                
                savePath = [panel.URL path];
                [self createModelFileWithResponseDic:responseDic name:name];
                
            }else{
                NSLog(@"path url有问题");
            }
            
        }
        
        
    }];
    
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
        [self createClass:fileName forDic:itemsDic];

    }else{
        //
        NSString *fileName = [NSString stringWithFormat:@"DSL%@Model",name];
        [self createClass:fileName forDic:data];

    }
}
-(void)createClass:(NSString *)name forDic:(NSDictionary *)json {
    
    
    
    //yapi定义的类型object、array等
    NSString *typeStr = json[@"type"];
    JsonValueType type = [AutomaticCoderTool getTypeByYApiTypeString:typeStr];
    //备注
//    NSString *description = json[@"description"];
    
    if (type == kDictionary) {
        //准备模板
        NSMutableString *templateH =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentH"] encoding:NSUTF8StringEncoding error:nil];
        NSMutableString *templateM =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentM"] encoding:NSUTF8StringEncoding error:nil];

        //.h
        //name
        //property
        NSMutableString *proterty = [NSMutableString string];
        NSMutableString *import = [NSMutableString string];
        
        //属性
        NSDictionary *properties = json[@"properties"];
        for (NSString *subKey in properties.allKeys) {
            //key   merchantExt
            //valueDic    {"type":"object","properties":{...}}
            NSDictionary *subDic = properties[subKey];
            [proterty appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic].firstObject];
            [import appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic].lastObject];
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
        
        [templateH writeToFile:[NSString stringWithFormat:@"%@/%@.h",savePath,name]
                    atomically:NO
                      encoding:NSUTF8StringEncoding
                         error:nil];
        //.m文件
        
        
    }else if (type == kArray) {
        //属性
        NSDictionary *items = json[@"items"];
        [self createClass:name forDic:items];
    }
    
}

- (NSArray *)getFileInfoWithKey:(NSString *)key subDic:(NSDictionary *)subDic {
    
    NSString *subTypeStr = subDic[@"type"];
    JsonValueType subType = [AutomaticCoderTool getTypeByYApiTypeString:subTypeStr];
    //类型名称 NSString、NSNumber等
    NSString *subTypeName = [AutomaticCoderTool typeNameWithType:subType];
    //备注
    NSString *description = subDic[@"description"];
    
    NSString *propertyString = @"";
    NSString *importString = @"";
    
    switch (subType) {
        case kString:
            
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,copy) %@ *%@;///<%@\n",subTypeName, key, description?:@"无"];
            break;
        case kNumber:
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,strong) %@ *%@;///<%@\n",subTypeName , key, description?:@"无"];
            break;
        case kArray:
        {
            NSString *fileName = [NSString stringWithFormat:@"%@Entity",[key capitalizedString]];
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,strong) NSMutableArray *%@;///<%@\n" , key, description?:@"无"];
            importString = [NSString stringWithFormat:@"#import \"%@.h\"\n",fileName];
            [self createClass:fileName forDic:subDic];
        }
            break;
        case kDictionary:
        {
            NSString *fileName = [NSString stringWithFormat:@"%@Entity",[key capitalizedString]];
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,strong) %@ *%@;///<%@\n",fileName , key, description?:@"无"];
            importString = [NSString stringWithFormat:@"#import \"%@.h\"\n",fileName];
            [self createClass:key forDic:subDic];
        }
            break;
        case kBool:
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,assign) %@ %@;///<%@\n",subTypeName , key, description?:@"无"];
            break;
        default:
            break;
    }
    
    return @[propertyString,importString];
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
