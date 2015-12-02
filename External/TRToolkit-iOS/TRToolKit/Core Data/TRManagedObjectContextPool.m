//
//  TRManagedObjectContextPool.m
//  Chowderios
//
//  Created by Pedro Gomes on 31/01/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRManagedObjectContextPool.h"
#import "TRDataStackManager.h"
#import "TRLog.h"

NSTimeInterval kTRManagedObjectContextIdleTTL = 60.0;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRDataStackManagerProtocol;
@interface TRManagedObjectContextPool ()

@property (nonatomic, weak) id<TRDataStackManagerProtocol> stackManager;
@property (nonatomic, assign) NSUInteger poolSize;
@property (nonatomic, assign) NSTimeInterval objectLifetime;
@property (nonatomic, strong) NSMutableArray *contextPool;
@property (nonatomic, strong) NSMutableDictionary *contextsByIdentifier;
@property (nonatomic, strong) NSMutableDictionary *contextUsageByIdentifier;

@property (nonatomic, strong) dispatch_queue_t lockQueue;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRManagedObjectContextPool

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithPoolSize:(NSUInteger)size
                    stackManager:(id<TRDataStackManagerProtocol>)stackManager
{
    if((self = [self initWithPoolSize:size lifetime:kTRManagedObjectContextIdleTTL stackManager:stackManager])) {
        
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithPoolSize:(NSUInteger)size
                        lifetime:(NSTimeInterval)lifetime
                    stackManager:(id<TRDataStackManagerProtocol>)stackManager
{
    if((self = [super init])) {
        self.poolSize = size;
        self.objectLifetime = lifetime;
        self.contextPool = [NSMutableArray arrayWithCapacity:size];
        self.contextsByIdentifier = [NSMutableDictionary dictionary];
        self.contextUsageByIdentifier = [NSMutableDictionary dictionary];
        self.stackManager = stackManager;
        self.lockQueue = dispatch_queue_create("com.tr.chowder.managed-object.context-pool.", NULL);
    }
    return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)fetchContextWithIdentifier:(id<NSCopying>)identifier
{
    NSParameterAssert(identifier != nil);
    
    __block NSManagedObjectContext *context = nil;
    dispatch_sync(self.lockQueue, ^{
        if(self.contextsByIdentifier[identifier] == nil) {
            self.contextsByIdentifier[identifier] = [self _fetchContext];
        }
        self.contextUsageByIdentifier[identifier] = [NSDate date];
        context = self.contextsByIdentifier[identifier];
    });
    return context;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)flush
{
    dispatch_sync(self.lockQueue, ^{
        __block NSUInteger registeredObjectCount = 0;
        for(NSManagedObjectContext *context in self.contextPool) {
            registeredObjectCount += [context registeredObjects].count;
            [context performBlock:^{
                [context reset];
            }];
        }
        TRLogInfo(TRLogContextStackManager, @"*** Resetting background contexts. <registered_objects=%d>", (int)registeredObjectCount);
        [self _flushExpiredContexts];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)_fetchContext
{
    NSManagedObjectContext *context = nil;
    if(self.contextPool.count < self.poolSize) {
        context = [self.stackManager temporaryContext];
        [self.contextPool addObject:context];
        TRLogInfo(TRLogContextStackManager, @"*** ManagedObjectContext pool created a new context. <new_size=%d>, <max_size=%d>", (int)self.contextPool.count, (int)self.poolSize);
    }
    else {
        // TODO: instead of just returning a random context, could we not fetch the least recently used context? (pdcgomes 03.02.2014)
        context = self.contextPool[arc4random_uniform((u_int32_t)self.contextPool.count)];
    }
    return context;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_flushExpiredContexts
{
    NSDate *now = [NSDate date];
    NSMutableSet *expiredContextCandidates = [NSMutableSet set];
    // Pass #1: find all contexts whose last usage is beyond our threshold (pdcgomes 31.01.2014)
    [self.contextUsageByIdentifier enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> identifier, NSDate *lastFetchDate, BOOL *stop) {
        if([now timeIntervalSinceDate:lastFetchDate] > self.objectLifetime) {
            [expiredContextCandidates addObject:self.contextsByIdentifier[identifier]];
        }
    }];
    // Pass #2: in case the candidate context has been used recently by someone else, take it out of our list (pdcgomes 31.01.2014)
    [self.contextUsageByIdentifier enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> identifier, NSDate *lastFetchDate, BOOL *stop) {
        if([now timeIntervalSinceDate:lastFetchDate] <= self.objectLifetime) {
            if([expiredContextCandidates containsObject:self.contextsByIdentifier[identifier]]) {
                [expiredContextCandidates removeObject:self.contextsByIdentifier[identifier]];
            }
        }
    }];
    
    // For the remaining contexts, find all identifiers currently using them (pdcgomes 31.01.2014)
    NSMutableSet *expiredIdentifiers = [NSMutableSet set];
    [self.contextsByIdentifier enumerateKeysAndObjectsUsingBlock:^(id<NSCopying> identifier, NSManagedObjectContext *context, BOOL *stop) {
        if([expiredContextCandidates containsObject:context]) {
            [expiredIdentifiers addObject:identifier];
        }
    }];
    
    // Finally, remove all marked identifiers and contexts (pdcgomes 31.01.2014)
    if(expiredContextCandidates.count > 0) {
        TRLogInfo(TRLogContextStackManager, @"*** ManagedObjectContext pool drain. <contexts_removed=%lu>", (unsigned long)expiredContextCandidates.count);
    }

    for(id<NSCopying> identifier in expiredIdentifiers) {
        [self.contextsByIdentifier removeObjectForKey:identifier];
        [self.contextUsageByIdentifier removeObjectForKey:identifier];
    }
    for(NSManagedObjectContext *expiredContext in expiredContextCandidates) {
        [self.contextPool removeObject:expiredContext];
    }
}

@end
