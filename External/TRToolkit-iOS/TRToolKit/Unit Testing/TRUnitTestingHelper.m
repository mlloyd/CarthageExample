//
//  TRUnitTestingHelper.m
//  TRToolKit
//
//  Created by Pedro Gomes on 20/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import "TRUnitTestingHelper.h"
#import "TRDataStackManager.h"

@implementation TRUnitTestingHelper

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (TRDataStackManager *)createDataStackManagerWithModelURL:(NSURL *)modelURL
{
    NSURL *persistentStoreURL   = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"unit-tests.sqlite"];
    [[NSFileManager defaultManager] removeItemAtURL:persistentStoreURL error:nil];
    
    NSDictionary *configuration = @{kTRDataStackManagerDataModelURLKey: modelURL,
                                    kTRDataStackManagerPersistentStoreURLKey: persistentStoreURL};
    
    return [[TRDataStackManager alloc] initWithConfiguration:configuration];
}

@end

