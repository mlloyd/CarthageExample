//
//  TRDelegateContainer.h
//  TRFramework
//
//  Created by Pedro Gomes on 07/11/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>

// Notes: You can define TR_DELEGATE_CONTAINER_DEBUG somewhere in your application if you need to disable async invocation
// the upside of this is that it will make debugging easier, as it'll preserve the stack trace for each call
// (pdcgomes 03.01.2014)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extern NSString *const kTRDelegateContainerNonConformantObjectException;
extern NSString *const kTRDelegateContainerObjectDoesNotImplementRequiredSelectorException;
extern NSString *const kTRDelegateContainerConfigurationException;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class TRDelegateProxy;
@interface NSObject (TRDelegateProxy)

@property (nonatomic, readonly) TRDelegateProxy *delegateProxy;

- (NSUInteger)delegatesCount;

- (void)tr_registerDelegate:(id)delegate;
- (void)tr_deregisterDelegate:(id)delegate;

- (void)tr_notifyDelegatesWithBlock:(void (^)(id delegate))block;
- (void)tr_notifyDelegatesWithBlock:(void (^)(id delegate))block callbackQueue:(dispatch_queue_t)callbackQueue;

- (void)tr_notifyDelegatesWithBlockAndWait:(void (^)(id delegate))block;

- (id)tr_firstDelegateRespondingToSelector:(SEL)selector;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRDelegateProxy : NSObject

- (instancetype)initWithProtocol:(Protocol *)protocol;

- (void)configureWithProtocol:(Protocol *)protocol;

- (NSUInteger)delegatesCount;

- (void)registerDelegate:(id)delegate;
- (void)deregisterDelegate:(id)delegate;

- (void)notifyDelegatesWithBlock:(void (^)(id delegate))block;
- (void)notifyDelegatesWithBlock:(void (^)(id))block completionHandler:(dispatch_block_t)completionHandler;

- (void)notifyDelegatesWithBlock:(void (^)(id delegate))block callbackQueue:(dispatch_queue_t)callbackQueue;
- (void)notifyDelegatesWithBlock:(void (^)(id delegate))block callbackQueue:(dispatch_queue_t)callbackQueue completionHandler:(dispatch_block_t)completionHandler;

- (void)notifyDelegatesWithBlockAndWait:(void (^)(id delegate))block;

- (id)firstDelegateRespondingToSelector:(SEL)selector;

@end

////////////////////////////////////////////////////////////////////////////////
// Helper Macros
////////////////////////////////////////////////////////////////////////////////

/**
 * To suppress compiler warnings, we can use this macro to declare protocol conformance for a specific protocol
 * To prevent naming clashes, the category name is prefixed with a uuid
 * This macro should normally only be used in private contexts (either implementation files or internal/private headers)
 */
#define TRDelegateProxyConformToProtocol(_protocolName_) \
@interface TRDelegateProxy(EB40AEB26C6B48349E84BB5AEEC722DA##_protocolName_) <_protocolName_> \
@end

