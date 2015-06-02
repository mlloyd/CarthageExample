//
//  CarthageExampleCoreTests.m
//  CarthageExampleCoreTests
//
//  Created by Martin Lloyd on 28/05/2015.
//  Copyright (c) 2015 Thomson Reuters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Mantle/Mantle.h>
@import CarthageExampleCore;

@interface CarthageExampleCoreTests : XCTestCase

@end

@implementation CarthageExampleCoreTests

- (void)setUp
{
    [super setUp];
    MTLModel *model = [[MTLModel alloc] init];
    model = nil;
    
    CEModel *ceModel = [[CEModel alloc] init];
    ceModel = nil;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

@end
