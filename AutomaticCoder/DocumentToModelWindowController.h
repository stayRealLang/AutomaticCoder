//
//  DocumentToModelWindowController.h
//  AutomaticCoder
//
//  Created by lang on 2020/12/17.
//  Copyright © 2020 me.zhangxi. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DocumentToModelWindowController : NSWindowController

@property (unsafe_unretained) IBOutlet NSTextView *docContent;
@property (weak) IBOutlet NSTextField *ClassName;
@property (weak) IBOutlet NSMatrix *matrix;

@end

NS_ASSUME_NONNULL_END
