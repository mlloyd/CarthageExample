//
//  UIDevice+TRAdditions.m
//  Chowderios
//
//  Created by Pedro Gomes on 13/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources. All rights reserved.
//

#import "UIDevice+TRAdditions.h"
#import "TRLog.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface UIDevice(TRInternal)

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation UIDevice(TRAdditions)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSNumber *)totalDiskSpace
{
    uint64_t totalSpace = 0;
//    uint64_t totalFreeSpace = 0;
    
    
    __autoreleasing NSError *error = nil;  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    
    if(dictionary) {  
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];  
//        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
//        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
//        TRLogTrace(TRLogContextDefault, @"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } 
    else {  
        TRLogTrace(TRLogContextDefault, @"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);  
    }  
    
    return [NSNumber numberWithUnsignedLongLong:totalSpace];
}

////////////////////////////////////////////////////////////////////////////////
// Taken from: http://stackoverflow.com/questions/5712527/ios-how-to-detect-total-available-free-disk-space-on-the-iphone-ipad-device
////////////////////////////////////////////////////////////////////////////////
- (NSNumber *)freeDiskSpace
{
//    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    
    __autoreleasing NSError *error = nil;  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:&error];
    
    if(dictionary) {  
//        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
//        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
//        TRLogTrace(TRLogContextDefault, @"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } 
    else {  
        TRLogTrace(TRLogContextDefault, @"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);  
    }  
    
    return [NSNumber numberWithUnsignedLongLong:totalFreeSpace];
}

#pragma mark - Internal Methods

@end
