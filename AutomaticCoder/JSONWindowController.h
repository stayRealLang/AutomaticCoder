//
//  JSONWindowController.h
//  AutomaticCoder
//
//  Created by 张 玺 on 12-8-20.
//  Copyright (c) 2012年 me.zhangxi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "JSONPropertyWindowController.h"
#import "AutomaticCoderTool.h"


@interface JSONWindowController : NSWindowController
{
    NSString *path;
    NSArrayController *array;
    NSArrayController *arrayController;
    JSONPropertyWindowController *propertyWindowController;
}
@property (unsafe_unretained) IBOutlet NSTextView *jsonContent;
@property (weak) IBOutlet NSTextField *jsonName;
@property (weak) IBOutlet NSTextField *preName;
@property (weak) IBOutlet NSTextField *jsonURL;
@property (weak) IBOutlet NSMatrix *matrix;

- (IBAction)useTestURL:(id)sender;
- (IBAction)getJSONWithURL:(id)sender;
- (IBAction)generateClass:(id)sender;
- (IBAction)checkProperty:(id)sender;




-(BOOL)isDataArray:(NSArray *)array;
-(JsonValueType)type:(id)obj;
-(NSString *)typeName:(JsonValueType)type;

@end
