//
//  TRStateProtocol.h
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRStateTransition;
@class TRStateMachine;
@protocol TRState <NSObject, NSCopying>

@property (nonatomic, weak) TRStateMachine *owner;
@property (nonatomic, copy, readonly) NSString *identifier;

- (void)addTransition:(id<TRStateTransition>)transition toState:(id<TRState>)state;
- (void)deleteTransition:(id<TRStateTransition>)transition;

- (id<TRState>)stateForTransition:(id<TRStateTransition>)transition;

- (void)enter;
- (void)execute;
- (void)exit;

- (void)printTransitions;
- (NSString *)stringRepresentation;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRStartState <TRState>

+ (instancetype)state;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRPreviousState <TRState>

+ (instancetype)state;

@end
