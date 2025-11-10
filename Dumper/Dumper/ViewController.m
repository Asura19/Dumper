//
//  ViewController.m
//  Dumper
//
//  Created by phoenix on 2025/11/10.
//

#import "ViewController.h"
#import "FrameworkDumper.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [FrameworkDumper dumpFrameworkAtPath:@"/System/Library/PrivateFrameworks/SpringBoardUIServices.framework"];
}


@end
