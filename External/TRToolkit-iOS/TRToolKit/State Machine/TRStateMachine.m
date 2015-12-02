//
//  TRStateMachine.m
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <AssertMacros.h>
#import "TRMacros.h"
#import "TRState.h"
#import "TRStateMachine.h"
#import "TRStateProtocol.h"
#import "TRStateTransition.h"
#import "TRStateTransitionProtocol.h"
#import "TRStack.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *TRStateMachineDuplicateStateException      = @"TRStateMachineDuplicateStateException";
NSString *TRStateMachineDuplicateTransitionException = @"TRStateMachineDuplicateTransitionException";
NSString *TRStateMachineUnknownStateException        = @"TRStateMachineUnknownStateException";
NSString *TRStateMachineInvalidTransitionException   = @"TRStateMachineInvalidTransitionException";
NSString *TRStateMachineInvalidConfigurationException= @"TRStateMachineInvalidConfigurationException";

NSString *kConfigurationStatesKey           = @"States";
NSString *kConfigurationTransitionsKey      = @"Transitions";
NSString *kConfigurationTransitionNameKey   = @"Transition";
NSString *kConfigurationDestinationStateKey = @"DestinationState";
NSString *kConfigurationInitialStateKey     = @"InitialState";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRStateMachine ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSMutableSet *states;
@property (nonatomic, strong) TRStack *previousStateStack;

@property (nonatomic, strong) id<TRState> currentState;
@property (nonatomic, assign) BOOL performingTransition;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRStateMachine

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithName:(NSString *)name
{
    NSParameterAssert(name != nil);

    if((self = [super init])) {
        self.name = name;
        self.states = [NSMutableSet set];
        self.previousStateStack = [[TRStack alloc] initWithCapacity:1];
        self.raisesExceptionOnInvalidTransition = NO;
    }
    return self;
}
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithName:(NSString *)name initialState:(id<TRState>)state
{
    NSParameterAssert(name != nil);
    NSParameterAssert(state != nil);
    
    if((self = [self initWithName:name])) {
        [self registerState:state];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithName:(NSString *)name
               configuration:(NSDictionary *)configuration
          stateCreationBlock:(TRStateCreationBlock)block
{
    NSParameterAssert(name != nil);
    
    if((self = [self initWithName:name])) {
        self.name = name;
        self.states = [NSMutableSet set];
        self.raisesExceptionOnInvalidTransition = NO;
        [self _parseAndApplyConfiguration:configuration
                       stateCreationBlock:block];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerState:(id<TRState>)state
{
    NSParameterAssert(state != nil);
    
    if([self.states containsObject:state] == YES) {
        [NSException raise:TRStateMachineDuplicateStateException
                    format:@"State has been previously registered"];
    }
    [self.states addObject:state];
    if(self.states.count == 1) {
        self.currentState = state;
    }
    state.owner = self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterState:(id<TRState>)state
{
    NSParameterAssert(state != nil);
    
    if([self.states containsObject:state] == NO) {
        [NSException raise:TRStateMachineUnknownStateException
                    format:@"Attempted to deregister an unknown state"];
    }
    [self.states removeObject:state];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)addTransition:(id<TRStateTransition>)transition
            fromState:(id<TRState>)fromState
              toState:(id<TRState>)toState
{
    NSParameterAssert(transition != nil);
    NSParameterAssert(fromState != nil);
    NSParameterAssert(toState != nil);
    
    id<TRState> state = [self.states member:fromState];
    if(state == nil) {
        [self registerState:fromState];
        state = fromState;
    }
    id<TRState> toStateInternal = [self.states member:toState];
    if(toStateInternal == nil) {
        [self registerState:toState];
        toStateInternal = toState;
    }
    [state addTransition:transition toState:toStateInternal];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)execute
{
    assert(self.currentState != nil);
    [self.currentState execute];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performTransition:(id<TRStateTransition>)transition
{
    TR_RETURN_UNLESS(self.performingTransition == NO);
    
    id<TRState> transitionToState = [self.currentState stateForTransition:transition];
    if(transitionToState == nil) {
        if(self.raisesExceptionOnInvalidTransition == YES) {
            [NSException raise:TRStateMachineInvalidTransitionException
                        format:@"Attempted to perform an invalid transition. <from_state=%@>, <transition=%@>>",
             self.currentState.identifier,
             transition.identifier];
        }
        if(self.logTransitions == YES) {
            NSLog(@"Attempted to perform an invalid transition. <from_state=%@>, <transition=%@>",
                  self.currentState.identifier,
                  transition.identifier);
        }
        return;
    }
    
    transitionToState = [self.states member:transitionToState];
    assert(transitionToState != nil);

    if(self.logTransitions) {
        NSLog(@"<state_machine=%@>, <from_state=%@> -> <transition=%@> -> <to_state=%@>",
              self.name,
              self.currentState.identifier,
              transition.identifier,
              transitionToState.identifier);
    }

    self.performingTransition = YES;
    
    while([transitionToState isEqual:[TRPreviousState state]] == YES) {
        transitionToState = [self.previousStateStack pop];
    }
    
    [self.previousStateStack push:self.currentState];
    [self.currentState exit];
    
    self.currentState = transitionToState;
    
    [self.currentState enter];
    self.performingTransition = NO;

    [self.currentState execute];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)printStateMachine
{
    NSMutableString *dot = [[NSMutableString alloc] init];
    
    [dot appendString:@"digraph g {\n"];
    
    for(id <TRState> state in self.states) {
        [dot appendString:[state stringRepresentation]];
    }
    [dot appendString:@"}"];
    NSLog(@"%@", dot);
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_parseAndApplyConfiguration:(NSDictionary *)configuration stateCreationBlock:(TRStateCreationBlock)stateCreationBlock
{
    if(configuration[kConfigurationStatesKey] == nil) {
        [NSException raise:TRStateMachineInvalidConfigurationException
                    format:@"Missing \"States\" key"];
    }
    if(configuration[kConfigurationTransitionsKey] == nil) {
        [NSException raise:TRStateMachineInvalidConfigurationException
                    format:@"Missing \"Transitions\" key"];
    }
    
    NSArray *states           = configuration[kConfigurationStatesKey];
    NSDictionary *transitions = configuration[kConfigurationTransitionsKey];
    NSString *initialState    = configuration[kConfigurationInitialStateKey];
    
    [transitions enumerateKeysAndObjectsUsingBlock:^(NSString *fromStateName, NSArray *transitionConfigurations, BOOL *stop) {
        if([states containsObject:fromStateName] == NO) {
            [NSException raise:TRStateMachineInvalidConfigurationException
                        format:@"From State \"%@\" not declared in \"States\"", fromStateName];
        }

        id<TRState> fromState = stateCreationBlock(fromStateName);
        if(fromState == nil) {
            [NSException raise:TRStateMachineInvalidConfigurationException
                        format:@"Unable to create From State \"%@\"", fromStateName];
        }

        [transitionConfigurations enumerateObjectsUsingBlock:^(NSDictionary *transitionConfiguration, NSUInteger idx, BOOL *stop) {
            NSString *transitionIdentifier = transitionConfiguration[kConfigurationTransitionNameKey];
            NSString *destinationStateName = transitionConfiguration[kConfigurationDestinationStateKey];
            if([states containsObject:fromStateName] == NO) {
                [NSException raise:TRStateMachineInvalidConfigurationException
                            format:@"Destination State \"%@\" not declared in \"States\"", destinationStateName];
            }
            id<TRState> destinationState = stateCreationBlock(destinationStateName);
            if(destinationState == nil) {
                [NSException raise:TRStateMachineInvalidConfigurationException
                            format:@"Unable to create Destination State \"%@\"", destinationStateName];
            }
            TRStateTransition *transition = [TRStateTransition transitionWithIdentifier:transitionIdentifier];
            [self addTransition:transition fromState:fromState toState:destinationState];
        }];
        
        if([fromStateName isEqual:initialState]) {
            self.currentState = [self.states member:fromState];
        }
    }];
}

@end
