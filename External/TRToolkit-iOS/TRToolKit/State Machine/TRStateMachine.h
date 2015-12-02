//
//  TRStateMachine.h
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRStateTransitionProtocol.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extern NSString *TRStateMachineDuplicateStateException;
extern NSString *TRStateMachineDuplicateTransitionException;
extern NSString *TRStateMachineUnknownStateException;
extern NSString *TRStateMachineInvalidTransitionException;
extern NSString *TRStateMachineInvalidConfigurationException;

typedef id<TRState> (^TRStateCreationBlock)(NSString *stateClassName);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRState;
@interface TRStateMachine : NSObject

@property (nonatomic, strong, readonly) id<TRState> currentState;
@property (nonatomic, assign) BOOL raisesExceptionOnInvalidTransition;
@property (nonatomic, assign) BOOL logTransitions;

- (id)init __attribute__((unavailable("Use one the designated intializers")));

- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithName:(NSString *)name initialState:(id<TRState>)state;
- (instancetype)initWithName:(NSString *)name
               configuration:(NSDictionary *)configuration
          stateCreationBlock:(TRStateCreationBlock)block;

- (void)registerState:(id<TRState>)state;
- (void)deregisterState:(id<TRState>)state;

- (void)addTransition:(id<TRStateTransition>)transition
            fromState:(id<TRState>)fromState
              toState:(id<TRState>)toState;

//- (void)addTransitionFromState:(id<TRState>)state
//                       toState:(id<TRState>)state
//                 causedByEvent:(id)event;
//
//- (void)addTransitionFromState:(id)state
//                       toState:(id)state
//                        target:(id)target
//         preTransitionSelector:(SEL)preTransitionSelector
//        postTransitionSelector:(SEL)postTransitionSelector;
//
//- (void)addTransitionFromState:(id)state
//                       toState:(id)state
//            preTransitionBlock:(id)preTransitionBlock
//           postTransitionBlock:(id)postTransitionBlock;

- (void)performTransition:(id<TRStateTransition>)transition;
- (void)execute;

- (void)printStateMachine;

@end
