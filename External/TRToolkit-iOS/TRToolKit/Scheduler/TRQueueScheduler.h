//
//  TRQueueScheduler.h
//  TRToolKit
//
//  Created by Pedro Gomes on 21/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : long {
	TRSchedulerPriorityHigh = DISPATCH_QUEUE_PRIORITY_HIGH,
	TRSchedulerPriorityDefault = DISPATCH_QUEUE_PRIORITY_DEFAULT,
	TRSchedulerPriorityLow = DISPATCH_QUEUE_PRIORITY_LOW,
	TRSchedulerPriorityBackground = DISPATCH_QUEUE_PRIORITY_BACKGROUND,
} TRSchedulerPriority;

typedef void (^TRSchedulerRecursiveBlock)(void (^reschedule)(void));

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRDisposable;
@protocol TRScheduler <NSObject>

@optional

+ (id<TRScheduler>)immediateScheduler;
+ (id<TRScheduler>)mainThreadScheduler;

+ (id<TRScheduler>)schedulerWithPriority:(TRSchedulerPriority)priority name:(NSString *)name;
+ (id<TRScheduler>)schedulerWithPriority:(TRSchedulerPriority)priority;

+ (id<TRScheduler>)scheduler;
+ (id<TRScheduler>)currentScheduler;

- (id<TRDisposable>)schedule:(void (^)(void))block;
- (id<TRDisposable>)after:(NSDate *)date schedule:(void (^)(void))block;
- (id<TRDisposable>)afterDelay:(NSTimeInterval)delay schedule:(void (^)(void))block;
- (id<TRDisposable>)after:(NSDate *)date repeatingEvery:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway schedule:(void (^)(void))block;
- (id<TRDisposable>)scheduleRecursiveBlock:(TRSchedulerRecursiveBlock)recursiveBlock;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRQueueScheduler : NSObject <TRScheduler>

- (id)init __attribute__((unavailable("Use one of the available class methods")));

@end
