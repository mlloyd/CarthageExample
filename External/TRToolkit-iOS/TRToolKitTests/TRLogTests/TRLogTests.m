//
//  TRLogTests.m
//  TRToolKit
//
//  Created by Pedro Gomes on 21/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"
#import "TRLog.h"

enum {
    TRLogContextTestCase1 = 1 << 1,
    TRLogContextTestCase2 = 1 << 2,
};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRLogTests : XCTestCase

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRLogTests

- (void)setUp
{
    [super setUp];
    
    [TRLog registerContext:TRLogContextTestCase1 withName:@"TRLogContextTestCase1" andLabel:@"test_case1"];
    [TRLog registerContext:TRLogContextTestCase2 withName:@"TRLogContextTestCase2" andLabel:@"test_case2"];
    [TRLog ddSetLogLevel:TR_LOG_LEVEL];
    [TRLog setEnabledLoggingContexts:TRLogContextAll];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testLog
{
    TRLogInfo(TRLogContextTestCase1, @"This is a test");
    TRLogInfo(TRLogContextTestCase2, @"This is another test");
    
    [self waitForTimeout:1.0];
}

@end
