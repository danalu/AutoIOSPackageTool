//
//  CustomWIndowController.m
//  AutoIOSPackageTool
//
//  Created by DanaLu on 2018/2/12.
//  Copyright © 2018年 zl. All rights reserved.
//

#import "CustomWIndowController.h"

@interface CustomWIndowController ()<NSWindowDelegate>

@end

@implementation CustomWIndowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {
    NSSize originSize = self.window.frame.size;
    frameSize.height = originSize.height / originSize.width * frameSize.width;
    return frameSize;
}

@end
