//
//  ViewController.m
//  AutoIOSPackageTool
//
//  Created by DanaLu on 2018/2/12.
//  Copyright © 2018年 zl. All rights reserved.
//

#import "ViewController.h"

typedef enum : NSUInteger {
    PackageTypeAppStore = 1,
    PackageTypeFir = 2
} PackageType;

static NSString *const ShellPathKey = @"ShellPathKey";
static NSString *const VersionKey = @"VersionKey";
static NSString *const UpdateLogKey = @"updateLog";
static NSString *const ShouldSendEmailKey = @"ShouldSendEmailKey";

@interface ViewController()

@property (nonatomic, assign) PackageType packageType;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.projectPathTextField.textColor = [NSColor blueColor];
    self.packageType = PackageTypeFir;
    self.progressView.hidden = YES;
    self.progressDescLabel.hidden = YES;
    [self showLastParameters];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)openAppWithExecPath:(NSString *)execPath{
    NSTask *task = [[NSTask alloc]init];
    [task setLaunchPath:execPath];
    [task launch];
}

#pragma mark - event
- (IBAction)autoPackage:(id)sender {
    if (![self isValidWithPackageParameters]) {
        return;
    }
    
    [self updateSetupParameters];
    [self invokingShellScriptWithPackageType:self.packageType];
}

- (IBAction)autoPackageAndUpload:(id)sender {
    if (![self isValidWithPackageParameters]) {
        return;
    }
    
    [self updateSetupParameters];
   [self invokingShellScriptWithPackageType:self.packageType];
}

- (IBAction)packageTypeSelect:(id)sender {
    if (self.firRadio == sender) {
        self.packageType = PackageTypeFir;
    } else {
        self.packageType = PackageTypeAppStore;
    }
}

- (IBAction)selectProjectPath:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    __weak typeof(self)weakSelf = self;
    //是否可以创建文件夹
    panel.canCreateDirectories = NO;
    //是否可以选择文件夹
    panel.canChooseDirectories = NO;
    //是否可以选择文件
    panel.canChooseFiles = YES;
    //是否可以多选
    [panel setAllowsMultipleSelection:NO];
    //显示
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        //是否点击open 按钮
        if (result == NSModalResponseOK) {
            //NSURL *pathUrl = [panel URL];
            NSString *pathString = [panel.URLs.firstObject path];
            weakSelf.projectPathTextField.stringValue = pathString;
        }
    }];
}

- (void)printLog:(NSTimer*)timer {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSPipe *pipe = timer.userInfo;
        NSFileHandle *file = [pipe fileHandleForReading];
        NSData *data = file.availableData;
        __block NSString *strReturnFromShell = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *lastLog = self.packageLogTextView.string.length > 0 ? self.packageLogTextView.string : @"";
            if (strReturnFromShell.length > 0) {
                strReturnFromShell = [lastLog stringByAppendingString:strReturnFromShell];
                self.packageLogTextView.string = strReturnFromShell;
                [self.packageLogTextView scrollRangeToVisible:NSMakeRange(strReturnFromShell.length - 100, 100)];
            }
        });
    });
}

#pragma mark - tool
- (void)showAlertViewWithMessage:(NSString*)message
                           block:(void (^ __nullable)(NSModalResponse returnCode))handler {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message;
    [alert addButtonWithTitle:@"知道啦"];
    alert.alertStyle = NSAlertStyleInformational;
    [alert beginSheetModalForWindow:self.view.window completionHandler:handler];
}

- (BOOL)isValidWithPackageParameters {
    NSString *shellPath = self.projectPathTextField.stringValue;
    if (shellPath.length == 0) {
        [self showAlertViewWithMessage:@"请选择需要打包的脚本文件" block:^(NSModalResponse returnCode) {
            [self selectProjectPath:nil];
        }];
        return NO;
    }
    
    if (self.versionInputTextField.stringValue.length == 0) {
        [self showAlertViewWithMessage:@"请输入本次打包的版本号" block:^(NSModalResponse returnCode) {
            [self.versionInputTextField becomeFirstResponder];
        }];
        return NO;
    }
    
    if (self.updateLogTextView.string.length == 0) {
        [self showAlertViewWithMessage:@"请输入本次打包的更新文案" block:^(NSModalResponse returnCode) {
//            [self.updateLogTextView becomeFirstResponder];
        }];
        return NO;
    }

    return YES;
}

- (void)invokingShellScriptWithPackageType:(PackageType)type {
    //清除之前的Log.
    self.packageLogTextView.string = @"";
    
    NSString *shellPath = self.projectPathTextField.stringValue;
    NSTask *shellTask = [[NSTask alloc]init];
    [shellTask setLaunchPath:@"/bin/sh"];
    
    NSMutableArray *args = [NSMutableArray arrayWithObject:shellPath];
    NSString *version = self.versionInputTextField.stringValue;
    NSString *updateLog = self.updateLogTextView.string;
    [args addObjectsFromArray:@[@(self.packageType).stringValue, version, updateLog]];
    
    if (self.sendEmailRaido.state == NSControlStateValueOn) {
        //需要发送邮件.
        [args addObject:@(1).stringValue];
    } else {
        [args addObject:@(0).stringValue];
    }
    
    
    self.packageButton.enabled = NO;
    self.packageAndUploadButton.enabled = NO;
    self.progressView.hidden = NO;
    self.progressDescLabel.hidden = NO;
    [self.progressView startAnimation:nil];
    self.progressDescLabel.stringValue = @"正在打包中，请不要关闭窗口...";
    
    //向shell传递参数.
    [shellTask setArguments:args];
    NSPipe *pipe = [[NSPipe alloc] init];
    [shellTask setStandardOutput:pipe];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(printLog:) userInfo:pipe repeats:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [shellTask launch];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.timer fire];
        });
        [shellTask waitUntilExit];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.timer invalidate];
            self.timer = nil;
            [self printLog:self.timer];
            self.packageButton.enabled = YES;
            self.packageAndUploadButton.enabled = YES;
            
            int status = [shellTask terminationStatus];
            NSString *message = @"";
            if (status == 0) {
                message = @"打包完成，上传成功";
                self.progressDescLabel.stringValue = @"打包成功，已上传";
            } else {
                message = @"打包失败";
                self.progressDescLabel.stringValue = @"打包失败";
            }
            
            [self.progressView stopAnimation:nil];
            self.progressView.hidden = YES;
            [self showAlertViewWithMessage:message block:^(NSModalResponse returnCode) {
            }];
        });
    });
}

- (void)updateSetupParameters {
    NSString *shellPath = self.projectPathTextField.stringValue;
    NSString *version = self.versionInputTextField.stringValue;
    NSString *updateLog = self.updateLogTextView.string;
    NSNumber *sendEmailNumber = self.sendEmailRaido.state == NSControlStateValueOn ? @1 : @0;
    
    [self storeSetupValueToLocalWithkey:ShellPathKey value:shellPath];
    [self storeSetupValueToLocalWithkey:VersionKey value:version];
    [self storeSetupValueToLocalWithkey:UpdateLogKey value:updateLog];
    [self storeSetupValueToLocalWithkey:ShouldSendEmailKey value:sendEmailNumber];
}

- (void)showLastParameters {
    self.projectPathTextField.stringValue = [self getSetupValueWithKey:ShellPathKey];
    self.versionInputTextField.stringValue = [self getSetupValueWithKey:VersionKey];
    self.updateLogTextView.string = [self getSetupValueWithKey:UpdateLogKey];
    
    NSNumber *shouldSendEmail = [self getSetupValueWithKey:ShouldSendEmailKey];
    self.sendEmailRaido.state = shouldSendEmail.integerValue == 1 ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)storeSetupValueToLocalWithkey:(NSString*)key value:(id)value {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

- (id)getSetupValueWithKey:(NSString*)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    id value = [userDefaults objectForKey:key];
    if (value) {
        return value;
    }
    
    return @"";
}

@end
