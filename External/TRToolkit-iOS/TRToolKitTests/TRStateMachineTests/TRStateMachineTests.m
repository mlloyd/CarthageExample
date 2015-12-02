//
//  TRStateMachineTests.m
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRState.h"
#import "TRStateMachine.h"
#import "TRStateTransition.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRStateMachineTests : XCTestCase

@property (nonatomic, strong) TRStateMachine *stateMachine;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRStateMachineTests

- (void)setUp
{
    [super setUp];
    self.stateMachine = [[TRStateMachine alloc] initWithName:@"com.tr.state-machine.tests"];
    self.stateMachine.raisesExceptionOnInvalidTransition = YES;
}

- (void)tearDown
{
    [super tearDown];
    self.stateMachine = nil;
}

- (void)testValidTransitions
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    TRState *state4 = [[TRState alloc] initWithIdentifier:@"state4"];
    
    TRStateTransition *transition1 = [TRStateTransition transitionWithIdentifier:@"transition1"];
    TRStateTransition *transition2 = [TRStateTransition transitionWithIdentifier:@"transition2"];
    
    [self.stateMachine addTransition:transition1 fromState:state1 toState:state2];
    [self.stateMachine addTransition:transition2 fromState:state1 toState:state4];
    [self.stateMachine addTransition:transition1 fromState:state2 toState:state3];
    [self.stateMachine addTransition:transition2 fromState:state3 toState:state4];
    [self.stateMachine addTransition:transition1 fromState:state4 toState:state1];
    
    XCTAssertEqualObjects(self.stateMachine.currentState, state1, @"");
    [self.stateMachine performTransition:transition1];
    XCTAssertEqualObjects(self.stateMachine.currentState, state2, @"");
    [self.stateMachine performTransition:transition1];
    XCTAssertEqualObjects(self.stateMachine.currentState, state3, @"");
    [self.stateMachine performTransition:transition2];
    XCTAssertEqualObjects(self.stateMachine.currentState, state4, @"");
    [self.stateMachine performTransition:transition1];
    XCTAssertEqualObjects(self.stateMachine.currentState, state1, @"");
    [self.stateMachine performTransition:transition2];
    XCTAssertEqualObjects(self.stateMachine.currentState, state4, @"");
}

- (void)testInvalidTransitions
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    
    TRStateTransition *transition1 = [TRStateTransition transitionWithIdentifier:@"transition1"];
    TRStateTransition *transition2 = [TRStateTransition transitionWithIdentifier:@"transition2"];
    
    [self.stateMachine addTransition:transition1 fromState:state1 toState:state2];
    [self.stateMachine addTransition:transition2 fromState:state1 toState:state3];
    
    XCTAssertEqualObjects(self.stateMachine.currentState, state1, @"");
    [self.stateMachine performTransition:transition1];
    XCTAssertEqualObjects(self.stateMachine.currentState, state2, @"");

    XCTAssertThrows([self.stateMachine performTransition:transition2], @"");
}

- (void)testDuplicateStates
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    
    TRStateTransition *transition1 = [TRStateTransition transitionWithIdentifier:@"transition1"];
    
    XCTAssertThrows([self.stateMachine addTransition:transition1 fromState:state1 toState:state1], @"");
}

- (void)testDuplicateTransitions
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    
    TRStateTransition *transition1 = [TRStateTransition transitionWithIdentifier:@"transition1"];
    
    [self.stateMachine addTransition:transition1 fromState:state1 toState:state2];
    XCTAssertThrows([self.stateMachine addTransition:transition1 fromState:state1 toState:state3], @"");
}

- (void)testValidStateRegistration
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    
    [self.stateMachine registerState:state1];
    [self.stateMachine registerState:state2];
    [self.stateMachine registerState:state3];
}

- (void)testDuplicateStateRegistration
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state1"]; // deliberately named state1 (pdcgomes 06.02.2014)

    [self.stateMachine registerState:state1];
    [self.stateMachine registerState:state2];
    XCTAssertThrows([self.stateMachine registerState:state3], @"");
}

- (void)testValidStateDeregistration
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    
    [self.stateMachine registerState:state1];
    [self.stateMachine registerState:state2];
    [self.stateMachine registerState:state3];
    
    [self.stateMachine deregisterState:state1];
    [self.stateMachine deregisterState:state2];
    [self.stateMachine deregisterState:state3];
}

- (void)testInvalidStateDeregistration
{
    TRState *state1 = [[TRState alloc] initWithIdentifier:@"state1"];
    TRState *state2 = [[TRState alloc] initWithIdentifier:@"state2"];
    TRState *state3 = [[TRState alloc] initWithIdentifier:@"state3"];
    
    [self.stateMachine registerState:state1];
    [self.stateMachine registerState:state2];
    
    [self.stateMachine deregisterState:state1];
    [self.stateMachine deregisterState:state2];
    XCTAssertThrows([self.stateMachine deregisterState:state3], @"");
}

@end
