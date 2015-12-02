//
//  TRDataStackManagerTests.m
//  Chowderios
//
//  Created by Pedro Gomes on 31/01/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"

#import "TRDataStackManager.h"
#import "TRManagedObjectContextPool.h"
#import "TRUnitTestingMacros.h"
#import "TRUnitTestingHelper.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRDataStackManagerTests : XCTestCase

@property (nonatomic, strong) id<TRDataStackManagerProtocol> stackManager;

@end

@implementation TRDataStackManagerTests

- (void)setUp
{
    [super setUp];
    self.stackManager = [TRUnitTestingHelper createDataStackManagerWithModelURL:nil];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)DECLARE_TEST_METHOD(fetchContextWithIdentifier)
{
    NSUInteger poolSize = 4;
    TRManagedObjectContextPool *pool = [[TRManagedObjectContextPool alloc] initWithPoolSize:poolSize stackManager:self.stackManager];

    NSMutableSet *contexts = [NSMutableSet set];
    NSUInteger numberOfIdentifiers = 10;
    for(int i = 0; i < numberOfIdentifiers; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contexts addObject:context];
    }
    
    XCTAssertTrue(contexts.count == poolSize, @"");
    
    NSMutableSet *contextVerification = [NSMutableSet set];
    for(int i = 0; i < numberOfIdentifiers; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextVerification addObject:context];
    }
    
    XCTAssertEqualObjects(contexts, contextVerification, @"");
}

- (void)DECLARE_TEST_METHOD(flushContextPool)
{
    NSUInteger poolSize = 4;
    TRManagedObjectContextPool *pool = [[TRManagedObjectContextPool alloc] initWithPoolSize:poolSize
                                                                                   lifetime:1.0
                                                                               stackManager:self.stackManager];
    NSMutableSet *contextsBeforeFlushing = [NSMutableSet set];
    NSUInteger numberOfIdentifiers = 10;
    for(int i = 0; i < numberOfIdentifiers; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextsBeforeFlushing addObject:context];
    }
    XCTAssertTrue(contextsBeforeFlushing.count == poolSize, @"");
    
    NSMutableSet *contextVerification = [NSMutableSet set];
    for(int i = 0; i < numberOfIdentifiers; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextVerification addObject:context];
    }
    
    XCTAssertEqualObjects(contextsBeforeFlushing, contextVerification, @"");

    [self waitForTimeout:1.5];
    
    [pool flush];
    
    NSMutableSet *contextsAfterFlushing = [NSMutableSet set];
    for(int i = 0; i < numberOfIdentifiers; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextsAfterFlushing addObject:context];
    }
    XCTAssertTrue(contextsAfterFlushing.count == poolSize, @"");
    XCTAssertNotEqual(contextsBeforeFlushing, contextsAfterFlushing, @"");
}

- (void)DECLARE_TEST_METHOD(flushContextPoolPartial)
{
    NSUInteger poolSize = 4;
    TRManagedObjectContextPool *pool = [[TRManagedObjectContextPool alloc] initWithPoolSize:poolSize
                                                                                   lifetime:1.0
                                                                               stackManager:self.stackManager];
    
    NSMutableArray *contextsBeforeFlushing = [NSMutableArray array];
    for(int i = 0; i < poolSize; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextsBeforeFlushing addObject:context];
    }
    
    XCTAssertTrue(contextsBeforeFlushing.count == poolSize, @"");
    
    [self waitForTimeout:1.5];

    [pool fetchContextWithIdentifier:@"context.identifier.1"];
    [pool fetchContextWithIdentifier:@"context.identifier.2"];
    
    [pool flush];
    
    NSMutableArray *contextsAfterFlushing = [NSMutableArray array];
    for(int i = 0; i < poolSize; i++) {
        NSString *identifier = [NSString stringWithFormat:@"context.identifier.%d", i + 1];
        NSManagedObjectContext *context = [pool fetchContextWithIdentifier:identifier];
        [contextsAfterFlushing addObject:context];
    }
    
    XCTAssertEqual(contextsBeforeFlushing[0], contextsAfterFlushing[0], @"");
    XCTAssertEqual(contextsBeforeFlushing[1], contextsAfterFlushing[1], @"");
    XCTAssertNotEqual(contextsBeforeFlushing[2], contextsAfterFlushing[2], @"");
    XCTAssertNotEqual(contextsBeforeFlushing[3], contextsAfterFlushing[3], @"");
}

@end
