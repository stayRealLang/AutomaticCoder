//
//  AppDelegate.m
//  AutomaticCoder
//
//  Created by 张 玺 on 12-8-20.
//  Copyright (c) 2012年 me.zhangxi. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

-(BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if(flag == NO)
    {
        [self.window makeKeyAndOrderFront:nil];
    }
    return YES;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //json = [[JSONWindowController alloc] initWithWindowNibName:@"JSONWindowController"];
    //[[json window] makeKeyAndOrderFront:nil];
}
- (NSString *) description
{
    NSString *result = @"";
    result = [result stringByAppendingFormat:@"%@ : %@\n",@"",@""];
    return result;
}

- (IBAction)json:(id)sender {

    json = [[JSONWindowController alloc] initWithWindowNibName:@"JSONWindowController"];
    [[json window] makeKeyAndOrderFront:nil];
}

- (IBAction)autoControlCode:(id)sender {
    autoControlCodeWC  = [[AutoControlCodeWindowController alloc] initWithWindowNibName:@"AutoControlCodeWindowController"];
    [[autoControlCodeWC window] makeKeyAndOrderFront:nil];
}

- (IBAction)docToModel:(NSButton *)sender {
    docToModelWC  = [[DocumentToModelWindowController alloc] initWithWindowNibName:@"DocumentToModelWindowController"];
    [[docToModelWC window] makeKeyAndOrderFront:nil];
}

- (IBAction)yapiFunction:(NSButton *)sender {
    yapiFileWC = [[YApiToCodeFileController alloc] initWithWindowNibName:@"YApiToCodeFileController"];
    [[yapiFileWC window] makeKeyAndOrderFront:nil];
}

@end
