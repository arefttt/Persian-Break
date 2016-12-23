//
//  ViewController.m
//  Persian Break
//
//  Created by areft on 12/23/16.
//  Copyright © 2016 Mohammad Aref Tamanadar. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}
- (IBAction)JBITBTN:(id)sender {
    NSString *appPath = [[NSBundle mainBundle] bundlePath];
    NSString *scriptPath = [appPath stringByAppendingPathComponent:@"Contents/Resources/yalu/run.sh"];
    NSTask *task = [[NSTask alloc] init];
    [task setArguments:@[scriptPath]];
    [task setLaunchPath:@"/bin/sh"];
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    NSPipe *input = [NSPipe pipe];
    [task setStandardOutput: pipe];
    [task setStandardInput: input];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *scriptLog;
    scriptLog = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    [self.LogView  setString:scriptLog];

    

}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
