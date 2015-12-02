//
//  TRDelegatesContainerTests.m
//  Chowderios
//
//  Created by Pedro Gomes on 04/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRDelegateContainer.h"
#import "TRMockProtocol.h"
#import "TRMockProtocolConformantObject.h"
#import "TRMockProtocolConformantInvalidObject.h"
#import "TRMockProtocolNonConformantObject.h"
#import "TRMockProtocolPartiallyConformantObject.h"
#import "TRUnitTestingMacros.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
TRDelegateContainerConformToProtocol(TRMockProtocol);

@interface NSObject (TRInvalidMethods)

- (void)mockInvalidMethod;

@end

@interface TRDelegatesContainerTests : XCTestCase

@property (nonatomic, strong) TRDelegateContainer *delegateProxy;

@end

@implementation TRDelegatesContainerTests

- (void)setUp
{
    [super setUp];
    self.delegateProxy = [[TRDelegateContainer alloc] initWithProtocol:@protocol(TRMockProtocol)];
}

- (void)tearDown
{
    [super tearDown];
    self.delegateProxy = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(validConformantObject)
{
    NSUInteger expectedCallbackCounter = 6;
    __block NSUInteger callbackCounter = 0;
    
    __strong TRMockProtocolConformantObject *conformantObject = [[TRMockProtocolConformantObject alloc] init];
    conformantObject.onInvocationBlock = ^{
        callbackCounter++;
    };

    @try {
        [self.delegateProxy registerDelegate:conformantObject];
        
        [self.delegateProxy mockRequiredMethod];
        [self.delegateProxy mockRequiredMethodWithObject:@""];
        [self.delegateProxy mockRequiredMethodWithObject:@"" andObject:@""];
        
        [self.delegateProxy mockOptionalInstanceMethod];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@""];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@"" andObject:@""];
    }
    @catch (NSException *exception) {
        XCTFail(@"");
        return;
    }
    
    NSUInteger iteration = 1;
    NSUInteger maxIterations = 3;

    // Because of the async nature of the callbacks from the delegate proxy, we need to wait (pdcgomes 04.12.2013)
    while(callbackCounter <= expectedCallbackCounter &&
          iteration <= maxIterations) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        iteration++;
    }
    XCTAssertEqual(expectedCallbackCounter, callbackCounter, @"");
    conformantObject = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(validMultipleConformantObjects)
{
    NSUInteger numberOfMockObjects = 32;
    NSUInteger expectedCallbackCounter = numberOfMockObjects * 6;
    __block NSUInteger callbackCounter = 0;
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:numberOfMockObjects];
    
    for(int i = 0; i < numberOfMockObjects; i++) {
        TRMockProtocolConformantObject *object = [[TRMockProtocolConformantObject alloc] init];
        object.onInvocationBlock = ^{
            callbackCounter++;
        };
        [objects addObject:object];
    }
    
    @try {
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.delegateProxy registerDelegate:obj];
        }];
        
        [self.delegateProxy mockRequiredMethod];
        [self.delegateProxy mockRequiredMethodWithObject:@""];
        [self.delegateProxy mockRequiredMethodWithObject:@"" andObject:@""];
        
        [self.delegateProxy mockOptionalInstanceMethod];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@""];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@"" andObject:@""];
    }
    @catch (NSException *exception) {
        XCTFail(@"");
        return;
    }
    
    NSUInteger iteration = 1;
    NSUInteger maxIterations = 3;
    
    // Because of the async nature of the callbacks from the delegate proxy, we need to wait (pdcgomes 04.12.2013)
    while(callbackCounter <= expectedCallbackCounter &&
          iteration <= maxIterations) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        iteration++;
    }
    XCTAssertEqual(expectedCallbackCounter, callbackCounter, @"");
    objects = nil;
}

////////////////////////////////////////////////////////////////////////////////
// The purpose of this test is to make sure that we cleanup internal caches
// for delegates that get deallocated
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(validMultipleConformantObjectsWhereSomeGetDeallocated)
{
    NSUInteger numberOfMockObjects = 32;
    NSUInteger numberOfObjectsToDeallocate = 8;
    NSUInteger expectedCallbackCounter = numberOfMockObjects * 6 - (numberOfObjectsToDeallocate * 6);
    __block NSUInteger callbackCounter = 0;
    
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:numberOfMockObjects];
    
    for(int i = 0; i < numberOfMockObjects; i++) {
        TRMockProtocolConformantObject *object = [[TRMockProtocolConformantObject alloc] init];
        object.onInvocationBlock = ^{
            callbackCounter++;
        };
        [objects addObject:object];
    }
    
    @try {
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.delegateProxy registerDelegate:obj];
        }];
        
        [objects removeObjectsInRange:NSMakeRange(0, numberOfObjectsToDeallocate)];
        // hopefully arc will cleanup after us (pdcgomes 04.12.2013)
        
        [self.delegateProxy mockRequiredMethod];
        [self.delegateProxy mockRequiredMethodWithObject:@""];
        [self.delegateProxy mockRequiredMethodWithObject:@"" andObject:@""];
        
        [self.delegateProxy mockOptionalInstanceMethod];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@""];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@"" andObject:@""];
    }
    @catch (NSException *exception) {
        XCTFail(@"");
        return;
    }
    
    NSUInteger iteration = 1;
    NSUInteger maxIterations = 3;
    
    // Because of the async nature of the callbacks from the delegate proxy, we need to wait (pdcgomes 04.12.2013)
    while(callbackCounter <= expectedCallbackCounter &&
          iteration <= maxIterations) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        iteration++;
    }
    XCTAssertEqual(expectedCallbackCounter, callbackCounter, @"");
    objects = nil;
    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(invalidConformantObject)
{
    __strong TRMockProtocolConformantInvalidObject *invalidConformantObject = [[TRMockProtocolConformantInvalidObject alloc] init];
    
    @try {
        [self.delegateProxy registerDelegate:invalidConformantObject];
    }
    @catch (NSException *exception) {
        XCTAssertTrue([exception.name isEqualToString:kTRDelegateContainerObjectDoesNotImplementRequiredSelectorException], @"");
        return;
    }
    @finally {
        invalidConformantObject = nil;
    }
    
    XCTFail(@"Test failed");

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(nonConformantObject)
{
    __strong TRMockProtocolNonConformantObject *nonConformantObject = [[TRMockProtocolNonConformantObject alloc] init];
    
    @try {
        [self.delegateProxy registerDelegate:nonConformantObject];
    }
    @catch (NSException *exception) {
        XCTAssertTrue([exception.name isEqualToString:kTRDelegateContainerNonConformantObjectException], @"");
        return;
    }
    @finally {
        nonConformantObject = nil;
    }

    XCTFail(@"Test failed");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(partiallyConformantObject)
{
    NSUInteger expectedCallbackCounter = 3; // The PartiallyConformant object only implements the required methods (pdcgomes 04.12.2013)
    __block NSUInteger callbackCounter = 0;

    
    __strong TRMockProtocolPartiallyConformantObject *conformantObject = [[TRMockProtocolPartiallyConformantObject alloc] init];
    conformantObject.onInvocationBlock = ^{
        callbackCounter++;
    };
    
    @try {
        [self.delegateProxy registerDelegate:conformantObject];
        
        [self.delegateProxy mockRequiredMethod];
        [self.delegateProxy mockRequiredMethodWithObject:@""];
        [self.delegateProxy mockRequiredMethodWithObject:@"" andObject:@""];
        
        [self.delegateProxy mockOptionalInstanceMethod];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@""];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@"" andObject:@""];
    }
    @catch (NSException *exception) {
        XCTFail(@"");
        return;
    }
    
    NSUInteger iteration = 1;
    NSUInteger maxIterations = 3;
    
    // Because of the async nature of the callbacks from the delegate proxy, we need to wait (pdcgomes 04.12.2013)
    while(callbackCounter <= expectedCallbackCounter &&
          iteration <= maxIterations) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        iteration++;
    }
    XCTAssertEqual(expectedCallbackCounter, callbackCounter, @"");
    conformantObject = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(reconfiguration)
{
    NSUInteger expectedCallbackCounter = 6;
    __block NSUInteger callbackCounter = 0;
    
    __strong TRMockProtocolConformantObject *conformantObject = [[TRMockProtocolConformantObject alloc] init];
    conformantObject.onInvocationBlock = ^{
        callbackCounter++;
    };
    
    @try {
        [self.delegateProxy configureWithProtocol:@protocol(TRMockProtocol)];
        
        [self.delegateProxy registerDelegate:conformantObject];
        
        [self.delegateProxy mockRequiredMethod];
        [self.delegateProxy mockRequiredMethodWithObject:@""];
        [self.delegateProxy mockRequiredMethodWithObject:@"" andObject:@""];
        
        [self.delegateProxy mockOptionalInstanceMethod];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@""];
        [self.delegateProxy mockOptionalInstanceMethodWithObject:@"" andObject:@""];
    }
    @catch (NSException *exception) {
        XCTFail(@"Test failed. Unexpected exception (%@)", exception);
        return;
    }
    
    NSUInteger iteration = 1;
    NSUInteger maxIterations = 3;
    
    // Because of the async nature of the callbacks from the delegate proxy, we need to wait (pdcgomes 04.12.2013)
    while(callbackCounter <= expectedCallbackCounter &&
          iteration <= maxIterations) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        iteration++;
    }
    XCTAssertEqual(expectedCallbackCounter, callbackCounter, @"");
    conformantObject = nil;
    
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(configurationException)
{
    __strong TRMockProtocolConformantObject *conformantObject = [[TRMockProtocolConformantObject alloc] init];
 
    @try {
        [self.delegateProxy registerDelegate:conformantObject];
        [self.delegateProxy configureWithProtocol:@protocol(TRMockProtocol)];
    }
    @catch (NSException *exception) {
        XCTAssertTrue([exception.name isEqualToString:kTRDelegateContainerConfigurationException], @"");
        return;
    }
    
    XCTFail(@"Test failed");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)DECLARE_TEST_METHOD(methodWithReturnType)
{
    TRMockProtocolConformantObject *conformantObject = [[TRMockProtocolConformantObject alloc] init];
    TRMockProtocolPartiallyConformantObject *partiallyConformantObject = [[TRMockProtocolPartiallyConformantObject alloc] init];
    
    [self.delegateProxy registerDelegate:conformantObject];
    [self.delegateProxy registerDelegate:partiallyConformantObject];
    
    NSString *result = [self.delegateProxy mockOptionalInstanceMethodWithNonVoidReturnType];
    XCTAssertTrue(result != nil, @"Result unexpectedly nil!");
}

@end
