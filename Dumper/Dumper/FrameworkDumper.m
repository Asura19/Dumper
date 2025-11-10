//
//  FrameworkDumper.m
//  LiveDetection
//
//  Created by phoenix on 2025/11/10.
//

//
//  FrameworkDumper.m
//  LiveDetection
//
//  Created by phoenix on 2025/11/10.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "FrameworkDumper.h"

@implementation FrameworkDumper

#pragma mark - 主方法

+ (void)dumpFrameworkAtPath:(NSString *)frameworkPath {
    NSBundle *bundle = [NSBundle bundleWithPath:frameworkPath];
    if (![bundle load]) {
        NSLog(@"❌ 无法加载框架: %@", frameworkPath);
        return;
    }
    
    NSString *executablePath = bundle.executablePath;
    const char *imageName = [executablePath UTF8String];
    
    NSLog(@"✅ 成功加载框架: %@", frameworkPath);
    NSLog(@"📦 开始 Dump 所有类...\n");
    
    [self dumpAllClassesInImage:imageName];
}

#pragma mark - Dump 所有类

+ (void)dumpAllClassesInImage:(const char *)imageName {
    unsigned int classCount = 0;
    const char **classNames = objc_copyClassNamesForImage(imageName, &classCount);
    
    NSLog(@"📊 找到 %u 个类\n", classCount);
    NSLog(@"==========================================\n");
    
    // 第一步：打印所有类名的概览
    NSLog(@"📋 ========== 所有类名概览 ==========\n");
    NSMutableArray *classList = [NSMutableArray array];
    
    for (unsigned int i = 0; i < classCount; i++) {
        const char *className = classNames[i];
        Class cls = objc_getClass(className);
        
        if (cls) {
            NSString *clsName = NSStringFromClass(cls);
            NSString *superclassName = NSStringFromClass([cls superclass]) ?: @"(null)";
            
            [classList addObject:@{
                @"class": cls,
                @"className": clsName,
                @"superclass": superclassName
            }];
            
            NSLog(@"%3u. %@ : %@", i + 1, clsName, superclassName);
        }
    }
    
    NSLog(@"\n");
    
    // 第二步：打印所有协议的概览
//    [self printAllProtocolsOverview];
    
    NSLog(@"\n");
    NSLog(@"==========================================");
    NSLog(@"📖 开始打印详细信息...\n");
    NSLog(@"==========================================\n");
    
    // 第三步：逐个打印类的详细信息
    NSMutableArray *allClassesInfo = [NSMutableArray array];
    
    for (NSDictionary *classDict in classList) {
        Class cls = classDict[@"class"];
        
        NSDictionary *classInfo = [self dumpClass:cls];
        [allClassesInfo addObject:classInfo];
        
        // 打印到控制台
        [self printClassInfo:classInfo];
        
        // 添加分隔线
        NSLog(@"");
    }
    
    free(classNames);
    
    // 保存到文件
    [self saveToFile:allClassesInfo frameworkImage:imageName];
}

#pragma mark - 打印所有协议概览

+ (void)printAllProtocolsOverview {
    unsigned int protocolCount = 0;
    Protocol * __unsafe_unretained *protocolList = objc_copyProtocolList(&protocolCount);
    
    NSLog(@"🔖 ========== 所有协议概览 ==========\n");
    NSLog(@"📊 总共找到 %u 个协议\n", protocolCount);
    
    // 收集所有协议名并排序
    NSMutableArray *protocolNames = [NSMutableArray array];
    for (unsigned int i = 0; i < protocolCount; i++) {
        Protocol *protocol = protocolList[i];
        NSString *protocolName = @(protocol_getName(protocol));
        [protocolNames addObject:protocolName];
    }
    
    [protocolNames sortUsingSelector:@selector(compare:)];
    
    // 按列打印协议名
    NSUInteger columnCount = 3; // 每行显示3个协议
    for (NSUInteger i = 0; i < protocolNames.count; i++) {
        if (i % columnCount == 0) {
            NSLog(@"");
        }
        printf("%-40s", [protocolNames[i] UTF8String]);
        if ((i + 1) % columnCount == 0) {
            printf("\n");
        }
    }
    
    printf("\n");
    free(protocolList);
}

#pragma mark - Dump 单个类

+ (NSDictionary *)dumpClass:(Class)cls {
    NSMutableDictionary *classInfo = [NSMutableDictionary dictionary];
    
    classInfo[@"className"] = NSStringFromClass(cls);
    classInfo[@"superclass"] = NSStringFromClass([cls superclass]) ?: @"(null)";
    
    // 1. 获取属性
    classInfo[@"properties"] = [self dumpPropertiesOfClass:cls];
    
    // 2. 获取实例变量
    classInfo[@"ivars"] = [self dumpIvarsOfClass:cls];
    
    // 3. 获取实例方法
    classInfo[@"instanceMethods"] = [self dumpMethodsOfClass:cls isClassMethod:NO];
    
    // 4. 获取类方法
    classInfo[@"classMethods"] = [self dumpMethodsOfClass:cls isClassMethod:YES];
    
    // 5. 获取协议
    classInfo[@"protocols"] = [self dumpProtocolsOfClass:cls];
    
    return classInfo;
}

#pragma mark - Dump 属性

+ (NSArray *)dumpPropertiesOfClass:(Class)cls {
    NSMutableArray *properties = [NSMutableArray array];
    
    unsigned int propertyCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(cls, &propertyCount);
    
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = propertyList[i];
        
        NSMutableDictionary *propertyInfo = [NSMutableDictionary dictionary];
        propertyInfo[@"name"] = @(property_getName(property));
        propertyInfo[@"attributes"] = @(property_getAttributes(property));
        
        [properties addObject:propertyInfo];
    }
    
    free(propertyList);
    return properties;
}

#pragma mark - Dump 实例变量

+ (NSArray *)dumpIvarsOfClass:(Class)cls {
    NSMutableArray *ivars = [NSMutableArray array];
    
    unsigned int ivarCount = 0;
    Ivar *ivarList = class_copyIvarList(cls, &ivarCount);
    
    for (unsigned int i = 0; i < ivarCount; i++) {
        Ivar ivar = ivarList[i];
        
        NSMutableDictionary *ivarInfo = [NSMutableDictionary dictionary];
        ivarInfo[@"name"] = @(ivar_getName(ivar));
        ivarInfo[@"type"] = @(ivar_getTypeEncoding(ivar));
        
        [ivars addObject:ivarInfo];
    }
    
    free(ivarList);
    return ivars;
}

#pragma mark - Dump 方法

+ (NSArray *)dumpMethodsOfClass:(Class)cls isClassMethod:(BOOL)isClassMethod {
    NSMutableArray *methods = [NSMutableArray array];
    
    Class targetClass = isClassMethod ? object_getClass(cls) : cls;
    
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(targetClass, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methodList[i];
        
        SEL selector = method_getName(method);
        const char *returnType = method_copyReturnType(method);
        unsigned int argumentCount = method_getNumberOfArguments(method);
        
        NSMutableDictionary *methodInfo = [NSMutableDictionary dictionary];
        methodInfo[@"selector"] = NSStringFromSelector(selector);
        methodInfo[@"returnType"] = @(returnType);
        
        // 获取参数类型
        NSMutableArray *argumentTypes = [NSMutableArray array];
        for (unsigned int j = 0; j < argumentCount; j++) {
            char *argType = method_copyArgumentType(method, j);
            [argumentTypes addObject:@(argType)];
            free(argType);
        }
        methodInfo[@"argumentTypes"] = argumentTypes;
        
        // 生成方法签名
        methodInfo[@"signature"] = [self generateMethodSignature:methodInfo
                                                   isClassMethod:isClassMethod];
        
        [methods addObject:methodInfo];
        free((void *)returnType);
    }
    
    free(methodList);
    return methods;
}

#pragma mark - Dump 协议

+ (NSArray *)dumpProtocolsOfClass:(Class)cls {
    NSMutableArray *protocols = [NSMutableArray array];
    
    unsigned int protocolCount = 0;
    Protocol * __unsafe_unretained *protocolList = class_copyProtocolList(cls, &protocolCount);
    
    for (unsigned int i = 0; i < protocolCount; i++) {
        Protocol *protocol = protocolList[i];
        [protocols addObject:@(protocol_getName(protocol))];
    }
    
    free(protocolList);
    return protocols;
}

#pragma mark - 辅助方法

+ (NSString *)generateMethodSignature:(NSDictionary *)methodInfo
                        isClassMethod:(BOOL)isClassMethod {
    NSString *prefix = isClassMethod ? @"+" : @"-";
    NSString *returnType = [self readableType:methodInfo[@"returnType"]];
    NSString *selector = methodInfo[@"selector"];
    NSArray *argTypes = methodInfo[@"argumentTypes"];
    
    // 简单的方法签名（无参数）
    if ([argTypes count] <= 2) {
        return [NSString stringWithFormat:@"%@ (%@)%@", prefix, returnType, selector];
    }
    
    // 带参数的方法签名
    NSMutableString *signature = [NSMutableString stringWithFormat:@"%@ (%@)", prefix, returnType];
    NSArray *selectorParts = [selector componentsSeparatedByString:@":"];
    
    for (NSUInteger i = 2; i < [argTypes count]; i++) {
        if (i - 2 < [selectorParts count]) {
            NSString *argType = [self readableType:argTypes[i]];
            [signature appendFormat:@"%@:(%@)arg%lu ",
                selectorParts[i - 2], argType, (unsigned long)(i - 2)];
        }
    }
    
    return signature;
}

+ (NSString *)readableType:(NSString *)typeEncoding {
    static NSDictionary *typeMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeMap = @{
            @"v": @"void",
            @"@": @"id",
            @"#": @"Class",
            @":": @"SEL",
            @"c": @"char",
            @"C": @"unsigned char",
            @"s": @"short",
            @"S": @"unsigned short",
            @"i": @"int",
            @"I": @"unsigned int",
            @"l": @"long",
            @"L": @"unsigned long",
            @"q": @"long long",
            @"Q": @"unsigned long long",
            @"f": @"float",
            @"d": @"double",
            @"B": @"BOOL",
            @"*": @"char *",
            @"^v": @"void *",
        };
    });
    
    // 处理对象类型 @"ClassName"
    if ([typeEncoding hasPrefix:@"@\""]) {
        NSString *className = [typeEncoding substringWithRange:NSMakeRange(2, typeEncoding.length - 3)];
        return [NSString stringWithFormat:@"%@ *", className];
    }
    
    return typeMap[typeEncoding] ?: typeEncoding;
}

#pragma mark - 打印输出

+ (void)printClassInfo:(NSDictionary *)classInfo {
    NSLog(@"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    NSLog(@"📱 类名: %@", classInfo[@"className"]);
    NSLog(@"📌 父类: %@", classInfo[@"superclass"]);
    
    // 协议
    NSArray *protocols = classInfo[@"protocols"];
    if (protocols.count > 0) {
        NSLog(@"📋 协议: %@", [protocols componentsJoinedByString:@", "]);
    }
    
    // 属性
    NSArray *properties = classInfo[@"properties"];
    if (properties.count > 0) {
        NSLog(@"\n🔸 属性 (%lu):", (unsigned long)properties.count);
        for (NSDictionary *prop in properties) {
            NSLog(@"  • %@", prop[@"name"]);
        }
    }
    
    // 实例变量
    NSArray *ivars = classInfo[@"ivars"];
    if (ivars.count > 0) {
        NSLog(@"\n🔹 实例变量 (%lu):", (unsigned long)ivars.count);
        for (NSDictionary *ivar in ivars) {
            NSLog(@"  • %@ : %@", ivar[@"name"], ivar[@"type"]);
        }
    }
    
    // 实例方法
    NSArray *instanceMethods = classInfo[@"instanceMethods"];
    if (instanceMethods.count > 0) {
        NSLog(@"\n⚡️ 实例方法 (%lu):", (unsigned long)instanceMethods.count);
        for (NSDictionary *method in instanceMethods) {
            NSLog(@"  %@", method[@"signature"]);
        }
    }
    
    // 类方法
    NSArray *classMethods = classInfo[@"classMethods"];
    if (classMethods.count > 0) {
        NSLog(@"\n⚡️ 类方法 (%lu):", (unsigned long)classMethods.count);
        for (NSDictionary *method in classMethods) {
            NSLog(@"  %@", method[@"signature"]);
        }
    }
    
    NSLog(@"\n");
}

#pragma mark - 保存到文件

+ (void)saveToFile:(NSArray *)classesInfo frameworkImage:(const char *)imageName {
    NSString *fileName = [[NSString stringWithUTF8String:imageName] lastPathComponent];
    NSString *outputPath = [NSString stringWithFormat:@"/tmp/%@_dump.json",
                           [fileName stringByDeletingPathExtension]];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:classesInfo
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (jsonData) {
        [jsonData writeToFile:outputPath atomically:YES];
        NSLog(@"💾 已保存到: %@", outputPath);
        
        // 同时保存可读格式
        NSString *readableOutput = [self generateReadableOutput:classesInfo];
        NSString *txtPath = [outputPath stringByReplacingOccurrencesOfString:@".json"
                                                                  withString:@".txt"];
        [readableOutput writeToFile:txtPath
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:nil];
        NSLog(@"📄 可读格式已保存到: %@", txtPath);
    } else {
        NSLog(@"❌ JSON 序列化失败: %@", error);
    }
}

+ (NSString *)generateReadableOutput:(NSArray *)classesInfo {
    NSMutableString *output = [NSMutableString string];
    
    [output appendString:@"/*\n"];
    [output appendString:@" * Private Framework Class Dump\n"];
    [output appendFormat:@" * Generated: %@\n", [NSDate date]];
    [output appendFormat:@" * Total Classes: %lu\n", (unsigned long)classesInfo.count];
    [output appendString:@" */\n\n"];
    
    // 首先输出所有类名的目录
    [output appendString:@"// ========== 类名目录 ==========\n"];
    [output appendString:@"/*\n"];
    for (NSDictionary *classInfo in classesInfo) {
        [output appendFormat:@" * %@ : %@\n",
            classInfo[@"className"], classInfo[@"superclass"]];
    }
    [output appendString:@" */\n\n"];
    [output appendString:@"// ========== 类详细信息 ==========\n\n"];
    
    // 然后输出详细信息
    for (NSDictionary *classInfo in classesInfo) {
        [output appendString:[self generateHeaderForClass:classInfo]];
        [output appendString:@"\n\n"];
    }
    
    return output;
}

+ (NSString *)generateHeaderForClass:(NSDictionary *)classInfo {
    NSMutableString *header = [NSMutableString string];
    
    // 类声明
    NSString *className = classInfo[@"className"];
    NSString *superclass = classInfo[@"superclass"];
    NSArray *protocols = classInfo[@"protocols"];
    
    [header appendString:@"@interface "];
    [header appendString:className];
    [header appendString:@" : "];
    [header appendString:superclass];
    
    if (protocols.count > 0) {
        [header appendFormat:@" <%@>", [protocols componentsJoinedByString:@", "]];
    }
    [header appendString:@"\n\n"];
    
    // 属性
    for (NSDictionary *prop in classInfo[@"properties"]) {
        [header appendFormat:@"@property %@;\n", prop[@"name"]];
    }
    
    if ([classInfo[@"properties"] count] > 0) {
        [header appendString:@"\n"];
    }
    
    // 实例方法
    for (NSDictionary *method in classInfo[@"instanceMethods"]) {
        [header appendFormat:@"%@;\n", method[@"signature"]];
    }
    
    if ([classInfo[@"instanceMethods"] count] > 0) {
        [header appendString:@"\n"];
    }
    
    // 类方法
    for (NSDictionary *method in classInfo[@"classMethods"]) {
        [header appendFormat:@"%@;\n", method[@"signature"]];
    }
    
    [header appendString:@"@end"];
    
    return header;
}

@end
