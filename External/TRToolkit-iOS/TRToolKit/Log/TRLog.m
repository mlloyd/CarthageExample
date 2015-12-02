//
//  TRLog.m
//  TRFramework
//
//  Created by Pedro Gomes on 13/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources. All rights reserved.
//

#import "TRLog.h"
#import "TRLogFormatter.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "UIDevice+TRAdditions.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *const kTREnabledLoggingContextsUserDefaultsKey = @"kEnabledLoggingContexts";

static int _TREnabledLoggingContexts = 0;
static int _ddLogLevel = LOG_LEVEL_VERBOSE;
static NSMutableDictionary *_TRRegisteredContexts;
static NSMutableDictionary *_TRRegisteredContextLabels;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *TRLogContextString(TRLogContext context)
{
    NSNumber *contextKey = @(context);
    if(_TRRegisteredContextLabels[contextKey]) {
        return _TRRegisteredContextLabels[contextKey];
    }
    if(_TRRegisteredContexts[contextKey]) {
        return _TRRegisteredContexts[contextKey];
    }
    return @"";
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *TRBatteryStateString(UIDeviceBatteryState state)
{
    switch(state) {
        case UIDeviceBatteryStateCharging: return @"Charging";
        case UIDeviceBatteryStateFull: return @"Full";
        case UIDeviceBatteryStateUnplugged: return @"Unplugged";
        default: return @"Unknown";
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRLog

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)initialize
{
 	TRLogFormatter *logFormatter = [[TRLogFormatter alloc] init];
	[[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
        tag:(id)tag
     format:(NSString *)format, ...
{
    va_list args;
    if(format) {
        va_start(args, format);
        
        [DDLog log:asynchronous
             level:level
              flag:flag
           context:context
              file:file
          function:function
              line:line
               tag:tag
            format:format
              args:args];
        
        va_end(args);

    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (int)ddLogLevel
{
    return _ddLogLevel;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)ddSetLogLevel:(int)logLevel
{
    _ddLogLevel = logLevel;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)registerContext:(NSUInteger)context withName:(NSString *)name
{
    assert(name != nil);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _TRRegisteredContexts = [[NSMutableDictionary alloc] init];
        _TRRegisteredContexts[@(TRLogContextDefault)] = @"";
    });
    
    if(_TRRegisteredContexts[@(context)] == nil) {
        _TRRegisteredContexts[@(context)] = [name copy];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)registerContext:(NSUInteger)context withName:(NSString *)name andLabel:(NSString *)label
{
    assert(name != nil);
    assert(label != nil);

    [[self class] registerContext:context withName:name];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _TRRegisteredContextLabels = [[NSMutableDictionary alloc] init];
    });
    if(_TRRegisteredContextLabels[@(context)] == nil) {
        _TRRegisteredContextLabels[@(context)] = [label copy];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)setEnabledLoggingContexts:(NSUInteger)contexts
{
    _TREnabledLoggingContexts = (int)contexts;
    
    [[NSUserDefaults standardUserDefaults] setObject:@(_TREnabledLoggingContexts) forKey:kTREnabledLoggingContextsUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (NSUInteger)enabledLoggingContexts
{
    return _TREnabledLoggingContexts;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (BOOL)isLoggingContextEnabled:(TRLogContext)context
{
    if((_TREnabledLoggingContexts & TRLogContextAll) == TRLogContextAll) {
        return YES;
    }
    return (_TREnabledLoggingContexts & context) == context;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)printEnabledLoggingContexts
{
    NSMutableDictionary *contexts = [NSMutableDictionary dictionary];
    [_TRRegisteredContexts enumerateKeysAndObjectsUsingBlock:^(NSNumber *contextKey, NSString *contextName, BOOL *stop) {
        contexts[contextName] = contextKey;
    }];
    NSArray *contextNames = [[contexts allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    NSUInteger maxContextNameLength = [[contextNames valueForKeyPath:@"@max.length"] intValue];
    NSMutableString *output = [[NSMutableString alloc] initWithString:
                               @"\n"
                               @"--- logging context flags ---\n"];
    [contextNames enumerateObjectsUsingBlock:^(NSString *contextName, NSUInteger idx, BOOL *stop) {
        NSUInteger context = [contexts[contextName] integerValue];
        NSUInteger paddingLength = maxContextNameLength - contextName.length;
        NSString *padding = @"";
        if(paddingLength > 0) {
            padding = [padding stringByPaddingToLength:paddingLength withString:@" " startingAtIndex:0];
        }
        BOOL isLoggingContextEnabled = [TRLog isLoggingContextEnabled:context];
        [output appendFormat:@"%@: %@%d\n", contextName, padding, isLoggingContextEnabled];
    }];
    
    TRLogInfo(TRLogContextDefault, @"%@", output);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (void)printDeviceInfo
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    [currentDevice setBatteryMonitoringEnabled:YES];
    
    NSString *deviceIdentificationString = [NSString stringWithFormat:@"%@, %@ %@ (%@)",
                                            currentDevice.name,
                                            currentDevice.model,
                                            currentDevice.systemName,
                                            currentDevice.systemVersion];
    
    unsigned long long totalDiskSpace = currentDevice.totalDiskSpace.unsignedLongLongValue;
    unsigned long long usedDiskSpace = currentDevice.totalDiskSpace.unsignedLongLongValue - currentDevice.freeDiskSpace.unsignedLongLongValue;
    unsigned long long freeDiskSpace = currentDevice.freeDiskSpace.unsignedLongLongValue;
    TRLogInfo(TRLogContextDefault,
               @"\n"
               @"--- device information ---\n"
               @"Device: %@ \n" // name, systemName, systemVersion
               @"Identifier: %@\n"
               @"Battery: %.0f%%, state: %@\n" // battery %, batteryState
               @"Storage: total: %@mb, used: %@mb, free: %@mb  \n" // used storage, free storage
               @"---------------------------",
               deviceIdentificationString,
               [currentDevice.identifierForVendor UUIDString],
               currentDevice.batteryLevel * 100.0,
               TRBatteryStateString(currentDevice.batteryState),
               @((totalDiskSpace/1024ll)/1024ll),
               @((usedDiskSpace/1024ll)/1024ll),
               @((freeDiskSpace/1024ll)/1024ll));
    [currentDevice setBatteryMonitoringEnabled:NO];
}

@end
