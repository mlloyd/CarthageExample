//
//  TRLogFormatter.m
//  Chowderios
//
//  Created by Pedro Gomes on 13/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources. All rights reserved.
//

#import "TRLogFormatter.h"
#import "TRLog.h"

@interface TRLogFormatter ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation TRLogFormatter

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    if ((self = [super init])) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [self.dateFormatter setDateFormat:@"HH:mm:ss:SSS"];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSUInteger enabledContexts = [TRLog enabledLoggingContexts];
    BOOL loggingForContextIsEnabled = (logMessage->_context == TRLogContextDefault ||
                                       ((logMessage->_context & enabledContexts) == logMessage->_context));
    if(!loggingForContextIsEnabled) {
        return nil;
    }
    
    NSString *logLevel = nil;
    switch (logMessage->_flag) {
        case LOG_FLAG_ERROR : logLevel = @"ERROR"; break;
        case LOG_FLAG_WARN  : logLevel = @"WARN"; break;
        case LOG_FLAG_INFO  : logLevel = @"INFO"; break;
        default             : logLevel = @"TRACE"; break;
    }
    
    NSString *dateAndTime = [self.dateFormatter stringFromDate:(logMessage->_timestamp)];
    NSString *logMsg = logMessage->_message;
    
    NSString *context = TRLogContextString(logMessage->_context);
    context = (context.length > 0 ? [NSString stringWithFormat:@" [%@]", context] : @"");
    return [NSString stringWithFormat:@"[%@] %@%@ %@",
            logLevel,
            dateAndTime,
            context,
            logMsg];
}

@end
