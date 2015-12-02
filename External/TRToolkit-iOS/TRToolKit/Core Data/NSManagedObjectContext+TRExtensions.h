//
//  NSManagedObjectContext+TRExtensions.h
//  Chowderios
//
//  Created by Pedro Gomes on 17/01/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void (^TRStackManagerFetchRequestResultBlock)(NSArray *result);
typedef void (^TRStackManagerFetchRequestError)(NSError *error);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface NSManagedObjectContext (TRExtensions)

- (NSArray *)executeFetchRequestInParentContext:(NSFetchRequest *)request
                                          error:(NSError *__autoreleasing *)error;
- (void)executeFetchRequestInParentContext:(NSFetchRequest *)request
                         completionHandler:(TRStackManagerFetchRequestResultBlock)completionHandler
                              errorHandler:(TRStackManagerFetchRequestError)errorHandler;

- (void)performBlock:(void (^)())block
             onEnter:(void (^)())onEnterBlock
              onExit:(void (^)())onExitBlock;
@end
