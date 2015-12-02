//
//  NSManagedObjectContext+TRExtensions.m
//  Chowderios
//
//  Created by Pedro Gomes on 17/01/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "NSManagedObjectContext+TRExtensions.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation NSManagedObjectContext (TRExtensions)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)executeFetchRequestInParentContext:(NSFetchRequest *)request error:(NSError * __autoreleasing *)outError
{
    NSManagedObjectContext *parentContext = self.parentContext;
    assert(parentContext != nil);

    __block NSArray *results = nil;
    __block NSError *innerError = nil;
    BOOL returnObjectsAsFaults = request.returnsObjectsAsFaults;
    
    [parentContext performBlockAndWait:^{
        NSFetchRequestResultType originalResultType = request.resultType;
        request.resultType = NSManagedObjectIDResultType;

        NSError *error = nil;
        NSArray *objectIDs = [parentContext executeFetchRequest:request error:&error];
        if(error) {
            innerError = error;
            return;
        }

        request.resultType = originalResultType;
        
//        [self performBlockAndWait:^{
//            NSError *error = nil;
        results = (returnObjectsAsFaults ?
                   [self objectsWithObjectIDs:objectIDs] :
                   [self faultedObjectsWithObjectIDs:objectIDs error:&error]);
//        }];

    }];
    
    if(outError != NULL && innerError != nil) {
        *outError = innerError;
    }
    return results;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)executeFetchRequestInParentContext:(NSFetchRequest *)request
                         completionHandler:(TRStackManagerFetchRequestResultBlock)completionHandler
                              errorHandler:(TRStackManagerFetchRequestError)errorHandler
{
    NSManagedObjectContext *parentContext = self.parentContext;
    assert(self.parentContext != nil);
    
    BOOL returnObjectsAsFaults = request.returnsObjectsAsFaults;
    
    [parentContext performBlock:^{
        NSError *error = nil;
        
        NSFetchRequestResultType originalResultType = request.resultType;
        request.resultType = NSManagedObjectIDResultType;
        
        NSArray *objectIDs = [parentContext executeFetchRequest:request error:&error];
        
        // Restore the original result type, in case the calling code still wants to use it
        request.resultType = originalResultType;
        
        [self performBlock:^{
            if(error) {
                errorHandler(error);
                return;
            }
            
            if(returnObjectsAsFaults) {
                NSArray *results = [self objectsWithObjectIDs:objectIDs];
                completionHandler(results);
            }
            else {
                [self faultedObjectsWithObjectIDs:objectIDs
                                completionHandler:completionHandler
                                     errorHandler:errorHandler];
            }
        }];
    }];
}

- (NSArray *)objectsWithObjectIDs:(NSArray *)objectIDs
{
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:objectIDs.count];
    [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger index, BOOL *stop) {
        NSManagedObject *object = [self objectWithID:objectID];
        [objects addObject:object];
    }];
    
    return [NSArray arrayWithArray:objects];
}

- (void)faultedObjectsWithObjectIDs:(NSArray *)objectIDs
                  completionHandler:(TRStackManagerFetchRequestResultBlock)completionHandler
                       errorHandler:(TRStackManagerFetchRequestError)errorHandler
{
    // Run this asynchronously because we are going to be calling performBlockAndWait multiple times
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^() {
        NSMutableArray *faultedObjects = [NSMutableArray arrayWithCapacity:objectIDs.count];
        __block NSError *error = nil;
        
        [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger index, BOOL *stop) {
            // By calling the performBlockAndWait each time, we don't block the thread while we fault all the objects at once, we just block it for each object and let it run in between. This increases the total run time for this method, but is helpful for the main thread, enabling user's to still interact in between faulting in each object.
            // We need to use performBlockAndWait instead of performBlock so that we maintain the order of the array we are populating
            [self performBlockAndWait:^{
                NSManagedObject *object = [self existingObjectWithID:objectID error:&error];
                if(object) {
                    [faultedObjects addObject:object];
                }
            }];
            
            if(error) {
                *stop = YES;
            }
        }];
        
        if(error) {
            faultedObjects = nil;
        }
        
        [self performBlock:^{
            error ? errorHandler(error) : completionHandler([NSArray arrayWithArray:faultedObjects]);
        }];
    });
}

- (NSArray *)faultedObjectsWithObjectIDs:(NSArray *)objectIDs error:(NSError * __autoreleasing *)error
{
    __block NSError *innerError = nil;
    NSMutableArray *faultedObjects = [NSMutableArray array];
    [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
        [self performBlockAndWait:^{
            NSManagedObject *object = [self existingObjectWithID:objectID error:&innerError];
            if(innerError != nil) {
                *stop = YES;
                return;
            }
            if(object != nil) {
                [faultedObjects addObject:object];
            }
        }];
    }];
 
    if(error != NULL && innerError != nil) {
        *error = innerError;
        return nil;
    }
    
    return [NSArray arrayWithArray:faultedObjects];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performBlock:(void (^)())block
             onEnter:(void (^)())onEnterBlock
              onExit:(void (^)())onExitBlock
{
    [self performBlock:^{
        onEnterBlock();
        [self performBlockAndWait:block];
        onExitBlock();
    }];
}

@end
