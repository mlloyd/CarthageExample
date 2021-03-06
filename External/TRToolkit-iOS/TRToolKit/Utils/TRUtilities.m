//
//  TRUtilities.m
//  TRToolKit
//
//  Created by Pedro Gomes on 07/03/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRUtilities.h"

#pragma mark - Environment Variables

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL TREnvironmentVariableIsDefined(NSString *variable)
{
    char *var = getenv([variable UTF8String]);
    return var != NULL;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
BOOL TREnvironmentVariableMatches(NSString *variable, NSString *value)
{
    const char *var = getenv([variable UTF8String]);
    const char *compareWithValue = [value UTF8String];
    
    return (var != NULL && strcmp(var, compareWithValue) == 0);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *TREnvironmentVariableValue(NSString *variable)
{
    const char *var = getenv([variable UTF8String]);
    
    return (var != NULL ? [NSString stringWithUTF8String:var] : nil);
}

#pragma mark - UUIDs

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString * TRCreatedUUID(void)
{
    return [[NSUUID UUID] UUIDString];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString * TRCreatedUUIDForCurrentDevice(void)
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}
