//
//  TRLog.h
//  TRFramework
//
//  Created by Pedro Gomes on 13/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
// Logging Contexts
////////////////////////////////////////////////////////////////////////////////
enum {
    TRLogContextDefault = 0,
    TRLogContextStackManager = 1 << 0,
    TRLogContextAll = 0xffff,
};
typedef NSUInteger TRLogContext;

extern NSString *TRLogContextString(TRLogContext context);

extern NSString *const kTREnabledLoggingContextsUserDefaultsKey;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRLog <NSObject>

@optional

+ (void)log:(BOOL)synchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(const char *)file
   function:(const char *)function
       line:(int)line
        tag:(id)tag
     format:(NSString *)format, ... __attribute__ ((format (__NSString__, 9, 10)));

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRLog : NSObject <TRLog>

+ (int)ddLogLevel;
+ (void)ddSetLogLevel:(int)logLevel;

+ (void)registerContext:(NSUInteger)context withName:(NSString *)name;
+ (void)registerContext:(NSUInteger)context withName:(NSString *)name andLabel:(NSString *)label;

+ (void)setEnabledLoggingContexts:(NSUInteger)contexts;
+ (NSUInteger)enabledLoggingContexts;
+ (BOOL)isLoggingContextEnabled:(TRLogContext)context;

+ (void)printDeviceInfo;
+ (void)printEnabledLoggingContexts;

@end

#import "TRUserLog.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define LOG_FLAG_ERROR    (1 << 0)  // 0...00001
#define LOG_FLAG_WARN     (1 << 1)  // 0...00010
#define LOG_FLAG_INFO     (1 << 2)  // 0...00100
#define LOG_FLAG_DEBUG    (1 << 3)  // 0...01000
#define LOG_FLAG_VERBOSE  (1 << 4)  // 0...10000

#define LOG_LEVEL_OFF     DDLogLevelOff
#define LOG_LEVEL_ERROR   (DDLogLevelError)                                                                          // 0...00001
#define LOG_LEVEL_WARN    (LOG_FLAG_ERROR | LOG_FLAG_WARN)                                                          // 0...00011
#define LOG_LEVEL_INFO    (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO)                                          // 0...00111
#define LOG_LEVEL_DEBUG   (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_DEBUG)                         // 0...01111
#define LOG_LEVEL_VERBOSE (LOG_FLAG_ERROR | LOG_FLAG_WARN | LOG_FLAG_INFO | LOG_FLAG_DEBUG | LOG_FLAG_VERBOSE)      // 0...11111

////////////////////////////////////////////////////////////////////////////////
// Current logging level
////////////////////////////////////////////////////////////////////////////////
#if defined(TR_LOG_LEVEL) && defined(DEBUG)
#else
    #ifdef TR_LOG_LEVEL
    #undef TR_LOG_LEVEL
    #endif

    #ifdef DEBUG
        #define TR_LOG_LEVEL (LOG_LEVEL_INFO)
    #else
        #define TR_LOG_LEVEL (LOG_LEVEL_INFO)
    #endif
#endif

static const int ddLogLevel = TR_LOG_LEVEL;

////////////////////////////////////////////////////////////////////////////////
// Bit mask to Control which logging contexts are enabled
// Default is *always* on
////////////////////////////////////////////////////////////////////////////////
#if !defined(DEBUG)
    #ifdef TR_ENABLED_LOGGING_CONTEXTS
    #undef TR_ENABLED_LOGGING_CONTEXTS
    #endif
#endif

#if !defined(TR_ENABLED_LOGGING_CONTEXTS)
#define TR_ENABLED_LOGGING_CONTEXTS (TRLogContextAll)

#endif

//static int TREnabledLoggingContexts = TR_ENABLED_LOGGING_CONTEXTS;

////////////////////////////////////////////////////////////////////////////////
// TR Logging macros
////////////////////////////////////////////////////////////////////////////////

#define LOG_ASYNC_ENABLED YES

#define LOG_ASYNC_ERROR    ( NO && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_WARN     (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_INFO     (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_DEBUG    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_VERBOSE  (YES && LOG_ASYNC_ENABLED)

#define TRLOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
    [TRLog log:isAsynchronous                                             \
         level:lvl                                                        \
          flag:flg                                                        \
       context:ctx                                                        \
          file:__FILE__                                                   \
      function:fnct                                                       \
          line:__LINE__                                                   \
           tag:atag                                                       \
        format:(frmt), ##__VA_ARGS__]

#define TRLOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...) \
    do { if((lvl & flg) && ([TRLog isLoggingContextEnabled:ctx])) TRLOG_MACRO(async, lvl, flg, ctx, nil, fnct, frmt, ##__VA_ARGS__); } while(0)

#define TRLOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
    TRLOG_MAYBE(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__)

////////////////////////////////////////////////////////////////////////////////
// TR Logging macros
////////////////////////////////////////////////////////////////////////////////

#define TRLogError(context, frmt, ...)    TRLOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   [TRLog ddLogLevel], LOG_FLAG_ERROR,   context, frmt, ##__VA_ARGS__)
#define TRLogWarn(context, frmt, ...)     TRLOG_OBJC_MAYBE(LOG_ASYNC_WARN,    [TRLog ddLogLevel], LOG_FLAG_WARN,    context, frmt, ##__VA_ARGS__)
#define TRLogInfo(context, frmt, ...)     TRLOG_OBJC_MAYBE(LOG_ASYNC_INFO,    [TRLog ddLogLevel], LOG_FLAG_INFO,    context, frmt, ##__VA_ARGS__)
#define TRLogTrace(context, frmt, ...)    TRLOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, [TRLog ddLogLevel], LOG_FLAG_VERBOSE, context, frmt, ##__VA_ARGS__)

#define TRLogCError(context, frmt, ...)   TRLOG_C_MAYBE(LOG_ASYNC_ERROR,   [TRLog ddLogLevel], LOG_FLAG_ERROR,   context, frmt, ##__VA_ARGS__)
#define TRLogCWarn(context, frmt, ...)    TRLOG_C_MAYBE(LOG_ASYNC_WARN,    [TRLog ddLogLevel], LOG_FLAG_WARN,    context, frmt, ##__VA_ARGS__)
#define TRLogCInfo(context, frmt, ...)    TRLOG_C_MAYBE(LOG_ASYNC_INFO,    [TRLog ddLogLevel], LOG_FLAG_INFO,    context, frmt, ##__VA_ARGS__)
#define TRLogCTrace(context, frmt, ...)   TRLOG_C_MAYBE(LOG_ASYNC_VERBOSE, [TRLog ddLogLevel], LOG_FLAG_VERBOSE, context, frmt, ##__VA_ARGS__)

#define THIS_CLASS NSStringFromClass([self class])

#define TRLogMethodEnter    TRLogTrace(@"Enter Method: [%@ %@]", THIS_CLASS, THIS_METHOD)
#define TRLogMethodExit     TRLogTrace(@"Exit Method: [%@ %@]", THIS_CLASS, THIS_METHOD)
#define TRTraceCall() do { TRLogTrace(TRLogContextDefault, @"%s", __PRETTY_FUNCTION__); } while(0)

////////////////////////////////////////////////////////////////////////////////
// COLOR SUPPORT FOR TTY LOGGING
// More: https://github.com/robbiehanson/CocoaLumberjack/wiki/XcodeColors
////////////////////////////////////////////////////////////////////////////////
#ifndef TR_LOGGING_ENABLE_COLORS
#define TR_LOGGING_ENABLE_COLORS (0)
#endif

#ifndef TR_LOGGING_COLOR_BG_SUCCESS
#define TR_LOGGING_COLOR_BG_SUCCESS (nil)
#endif

#ifndef TR_LOGGING_COLOR_FG_SUCCESS
#define TR_LOGGING_COLOR_FG_SUCCESS ([UIColor greenColor])
#endif

#ifndef TR_LOGGING_COLOR_BG_ERROR
#define TR_LOGGING_COLOR_BG_ERROR (nil)
#endif

#ifndef TR_LOGGING_COLOR_FG_ERROR
#define TR_LOGGING_COLOR_FG_ERROR ([UIColor redColor])
#endif

#ifndef TR_LOGGING_COLOR_BG_WARN
#define TR_LOGGING_COLOR_BG_WARN (nil)
#endif

#ifndef TR_LOGGING_COLOR_FG_WARN
#define TR_LOGGING_COLOR_FG_WARN ([UIColor orangeColor])
#endif

#ifndef TR_LOGGING_COLOR_BG_INFO
#define TR_LOGGING_COLOR_BG_INFO (nil)
#endif


#ifndef TR_LOGGING_COLOR_FG_INFO
#define TR_LOGGING_COLOR_FG_INFO ([UIColor colorWithRed:233.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0])
#endif

#ifndef TR_LOGGING_COLOR_BG_VERBOSE
#define TR_LOGGING_COLOR_BG_VERBOSE (nil)
#endif

#ifndef TR_LOGGING_COLOR_FG_VERBOSE
#define TR_LOGGING_COLOR_FG_VERBOSE ([UIColor colorWithRed:233.0/255.0 green:235.0/255.0 blue:235.0/255.0 alpha:1.0])
#endif
