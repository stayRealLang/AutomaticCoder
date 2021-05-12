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
@property (weak) IBOutlet NSTableView *subTableView;

@property(nonatomic, strong) NSMutableArray *dataArray;

@property(nonatomic, strong) NSDictionary *selectSectionDic;
@property(nonatomic, strong) NSDictionary *subSelectSectionDic;

@end

@implementation YApiToCodeFileController

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _subTableView.delegate = self;
    _subTableView.dataSource = self;
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
    
    if (_subSelectSectionDic) {
        [self anlysJson:@[_subSelectSectionDic]];
    }else {
        NSDictionary *sectionDic = _selectSectionDic;
        NSString *sectionName = sectionDic[@"name"];
        NSLog(@"sectionName:%@",sectionName);
        NSArray *sectionList = sectionDic[@"list"];
        
        [self anlysJson:sectionList];
    }
    
}

//解析json，获取需要的字段
- (void)anlysJson:(NSArray *)sectionList {
    
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
        [self createClass:fileName forDic:itemsDic inFolder:name];

    }else{
        //
        NSString *fileName = [NSString stringWithFormat:@"DSL%@Model",name];
        [self createClass:fileName forDic:data inFolder:name];

    }
}


/// 创建类文件方法，返回值表示最后是否创建
/// @param name 文件名
/// @param json 解析的json数据
/// @param folderPath 文件夹名称
-(BOOL)createClass:(NSString *)name forDic:(NSDictionary *)json inFolder:(NSString *)folderPath{
    
    
    
    //yapi定义的类型object、array等
    NSString *typeStr = json[@"type"];
    JsonValueType type = [AutomaticCoderTool getTypeByYApiTypeString:typeStr];
    //备注
//    NSString *description = json[@"description"];
    
    if (type == kDictionary) {
        //准备模板
        NSMutableString *templateH =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentH"] encoding:NSUTF8StringEncoding error:nil];
        NSMutableString *templateM =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentM"] encoding:NSUTF8StringEncoding error:nil];

        //.h文件
        NSMutableString *proterty = [NSMutableString string];
        NSMutableString *import = [NSMutableString string];
        
        //.m文件
        NSMutableString *encode = [NSMutableString string];
        NSMutableString *decode = [NSMutableString string];
        
        //属性
        NSDictionary *properties = json[@"properties"];
        for (NSString *subKey in properties.allKeys) {
            //key   merchantExt
            //valueDic    {"type":"object","properties":{...}}
            NSDictionary *subDic = properties[subKey];
            [proterty appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic  inFolder:folderPath].firstObject];
            [import appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic inFolder:folderPath][1]];
            [encode appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic  inFolder:folderPath][2]];
            [decode appendFormat:@"%@", [self getFileInfoWithKey:subKey subDic:subDic  inFolder:folderPath][3]];
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
        
        //修改.m模板
        [templateM replaceOccurrencesOfString:@"#name#"
                                   withString:name
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, templateM.length)];
        
        NSDictionary *replaceList =  @{
                                @"encode":encode,
                                @"decode":decode
                                };
        for(NSString *key in [replaceList allKeys]){
            
            [templateM replaceOccurrencesOfString:[NSString stringWithFormat:@"#%@#",key]
                                       withString:[replaceList objectForKey:key]
                                          options:NSCaseInsensitiveSearch
                                            range:NSMakeRange(0, templateM.length)];
            
        }
        
        NSString *dirPath = [NSString stringWithFormat:@"%@/%@",savePath,folderPath];
        BOOL isDir;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL existed = [fileManager fileExistsAtPath:dirPath isDirectory:&isDir];

        if (!(isDir == YES && existed == YES)){
            [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }

        
        [templateH writeToFile:[NSString stringWithFormat:@"%@/%@.h",dirPath,name]
                    atomically:NO
                      encoding:NSUTF8StringEncoding
                         error:nil];
        [templateM writeToFile:[NSString stringWithFormat:@"%@/%@.m",dirPath,name]
                    atomically:NO
                      encoding:NSUTF8StringEncoding
                         error:nil];
        return YES;
    }else if (type == kArray) {
        //属性
        NSDictionary *items = json[@"items"];
        return [self createClass:name forDic:items inFolder:folderPath];
    }
    return NO;
}

- (NSArray *)getFileInfoWithKey:(NSString *)key subDic:(NSDictionary *)subDic inFolder:(NSString *)folderPath{
    
    NSString *subTypeStr = subDic[@"type"];
    JsonValueType subType = [AutomaticCoderTool getTypeByYApiTypeString:subTypeStr];
    //类型名称 NSString、NSNumber等
    NSString *subTypeName = [AutomaticCoderTool typeNameWithType:subType];
    //备注
    NSString *description = subDic[@"description"];
    
    NSString *propertyString = @"";
    NSString *importString = @"";
    
    NSString *encode = @"";
    NSString *decode = @"";
    
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
            BOOL isCreate = [self createClass:fileName forDic:subDic inFolder:folderPath];
            if (isCreate) {
                importString = [NSString stringWithFormat:@"#import \"%@.h\"\n",fileName];
                propertyString = [NSString stringWithFormat:@"@property (nonatomic,strong) NSMutableArray<%@ *> *%@;///<%@\n", fileName, key, description?:@"无"];
            }
        }
            break;
        case kDictionary:
        {
            NSString *fileName = [NSString stringWithFormat:@"%@Entity",[key capitalizedString]];
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,strong) %@ *%@;///<%@\n",fileName , key, description?:@"无"];
            importString = [NSString stringWithFormat:@"#import \"%@.h\"\n",fileName];
            [self createClass:fileName forDic:subDic inFolder:folderPath];
        }
            break;
        case kBool:
            propertyString = [NSString stringWithFormat:@"@property (nonatomic,assign) %@ %@;///<%@\n",subTypeName , key, description?:@"无"];
            break;
        default:
            break;
    }
    encode = [NSString stringWithFormat:@"[aCoder encodeObject:self.%@ forKey:@\"zl_%@\"];\n\t",key,key];
    decode = [NSString stringWithFormat:@"self.%@ = [aDecoder decodeObjectForKey:@\"zl_%@\"];\n\t\t",key,key];
    return @[propertyString,importString,encode,decode];
}

#pragma mark - TableView Delegate
 -(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
     if (tableView == self.tableView) {
         return _dataArray.count;
         
     }else {
         return _selectSectionDic.count;
         
     }
 }

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    NSTableView *tableView = notification.object;
    if (tableView == self.tableView) {
        _selectSectionDic = _dataArray[tableView.selectedRow];
        [_subTableView reloadData];
    }else {
        _subSelectSectionDic = _selectSectionDic[@"list"][tableView.selectedRow];
    }
}

 -(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
     if (tableView == self.tableView) {
         NSDictionary *sectionDic = _dataArray[row];
         return sectionDic[@"name"];
         
     }else {
         NSDictionary *singleDic = _selectSectionDic[@"list"][row];
         return singleDic[@"title"];
         
     }
     
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
