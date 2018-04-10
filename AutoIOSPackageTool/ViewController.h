//
//  ViewController.h
//  AutoIOSPackageTool
//
//  Created by DanaLu on 2018/2/12.
//  Copyright © 2018年 zl. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSButton *firRadio;
@property (weak) IBOutlet NSButton *appStoreRadio;
@property (weak, nonatomic) IBOutlet NSButton *packageAndUploadButton;
@property (weak) IBOutlet NSTextField *versionInputTextField;
@property (weak) IBOutlet NSTextView *updateLogTextView;
@property (weak) IBOutlet NSTextView *packageLogTextView;
@property (weak, nonatomic) IBOutlet NSTextField *projectPathTextField;
@property (weak, nonatomic) IBOutlet NSButton *sendEmailRaido;
@property (weak) IBOutlet NSProgressIndicator *progressView;
@property (weak) IBOutlet NSTextField *progressDescLabel;

- (IBAction)autoPackage:(id)sender;
- (IBAction)autoPackageAndUpload:(id)sender;
- (IBAction)packageTypeSelect:(id)sender;
- (IBAction)selectProjectPath:(id)sender;

@end

