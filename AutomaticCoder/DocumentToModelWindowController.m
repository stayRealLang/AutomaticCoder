//
//  DocumentToModelWindowController.m
//  AutomaticCoder
//
//  Created by lang on 2020/12/17.
//  Copyright © 2020 me.zhangxi. All rights reserved.
//

#import "DocumentToModelWindowController.h"

@interface DocumentToModelWindowController ()

@end

@implementation DocumentToModelWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)createModelFile:(NSButton *)sender {
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        
        if(result == 0) return ;
        
        NSString *path = [panel.URL path];
        [self setupFileContentInPath:path];
        _docContent.string = [NSString stringWithFormat:@"模型文件已创建，路径:%@",path];
    
    }];
    
}

- (void)setupFileContentInPath:(NSString *)path{
    //准备模板
    NSMutableString *templateH =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentH"]
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:nil];
    NSMutableString *templateM =[[NSMutableString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"documentM"]
                                                                       encoding:NSUTF8StringEncoding
                                                                          error:nil];
    //.h
    //name
    //property
    NSMutableString *proterty = [NSMutableString string];
    NSMutableString *import = [NSMutableString string];
    //.m
    NSMutableString *encode = [NSMutableString string];
    NSMutableString *decode = [NSMutableString string];
    
    NSDictionary *list =  @{
                            @"encode":encode,
                            @"decode":decode
                            };
    
    NSArray *contentArr = [self.docContent.string componentsSeparatedByString:@"\n"];
    for (int index = 0; index < contentArr.count; index ++) {
        if ([@"number" isEqualToString:contentArr[index]] || [@"string" isEqualToString:contentArr[index]]) {
            //找到类型的index 以此来判断其他参数的位置
            NSString *remark = @"";
            NSString *secremark = @"";
            NSString *modifier = @"copy";
            NSString *type = @"NSString";
            NSString *name = @"";
            if ((index - 2) >= 0) {
                name = contentArr[index - 2];
                name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            if ((index - 1) >= 0) {
                remark = contentArr[index - 1];
            }
            NSString *currentType = contentArr[index];
            if ([@"number" isEqualToString:currentType]) {
                type = @"NSNumber";
                modifier = @"strong";
            }
            if (contentArr.count > (index + 1)) {
                secremark = contentArr[index + 1];
            }
            [proterty appendFormat:@"//%@(%@) \n@property (nonatomic, %@) %@ *%@;\n",remark,secremark,modifier,type,name];
            
            [encode appendFormat:@"[aCoder encodeObject:self.%@ forKey:@\"zx_%@\"];\n\t",name,name];
            [decode appendFormat:@"self.%@ = [aDecoder decodeObjectForKey:@\"zx_%@\"];\n\t\t",name,name];
        }
        
    }
    NSLog(@"%@",proterty);
    
    //修改.h模板
    [templateH replaceOccurrencesOfString:@"#name#"
                               withString:self.ClassName.stringValue
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
                               withString:self.ClassName.stringValue
                                  options:NSCaseInsensitiveSearch
                                    range:NSMakeRange(0, templateM.length)];
    
    for(NSString *key in [list allKeys]){
        
        [templateM replaceOccurrencesOfString:[NSString stringWithFormat:@"#%@#",key]
                                   withString:[list objectForKey:key]
                                      options:NSCaseInsensitiveSearch
                                        range:NSMakeRange(0, templateM.length)];
    }
    
    
    //写文件
    NSLog(@"%@",[NSString stringWithFormat:@"%@/%@.h",path,self.ClassName.stringValue]);
    [templateH writeToFile:[NSString stringWithFormat:@"%@/%@.h",path,self.ClassName.stringValue]
                atomically:NO
                  encoding:NSUTF8StringEncoding
                     error:nil];
    [templateM writeToFile:[NSString stringWithFormat:@"%@/%@.m",path,self.ClassName.stringValue]
                atomically:NO
                  encoding:NSUTF8StringEncoding
                     error:nil];
}

@end
