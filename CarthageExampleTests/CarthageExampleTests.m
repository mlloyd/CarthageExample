//
//  CarthageExampleTests.m
//  CarthageExampleTests
//
//  Created by Martin Lloyd on 28/05/2015.
//  Copyright (c) 2015 Thomson Reuters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Mantle/Mantle.h>

@interface CarthageExampleTests : XCTestCase

@end

@implementation CarthageExampleTests

- (void)setUp
{
    [super setUp];
    
    MTLModel *model = [[MTLModel alloc] init];
    model = nil;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
