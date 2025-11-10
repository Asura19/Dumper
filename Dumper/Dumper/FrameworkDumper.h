//
//  FrameworkDumper.h
//  LiveDetection
//
//  Created by phoenix on 2025/11/10.
//


#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface FrameworkDumper : NSObject

+ (void)dumpFrameworkAtPath:(NSString *)frameworkPath;
+ (void)dumpAllClassesInImage:(const char *)imageName;
+ (NSDictionary *)dumpClass:(Class)cls;

@end

