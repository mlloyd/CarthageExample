//
//  TRQueueScheduler.m
//  TRToolKit
//
//  Created by Pedro Gomes on 21/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "TRQueueScheduler.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRQueueScheduler

+ (id<TRScheduler>)immediateScheduler
{
    return (id<TRScheduler>)[RACQueueScheduler immediateScheduler];
}

+ (id<TRScheduler>)mainThreadScheduler
{
    return (id<TRScheduler>)[RACQueueScheduler mainThreadScheduler];
}

+ (id<TRScheduler>)schedulerWithPriority:(TRSchedulerPriority)priority name:(NSString *)name
{
    return (id<TRScheduler>)[RACQueueScheduler schedulerWithPriority:(RACSchedulerPriority)priority name:name];
}

+ (id<TRScheduler>)schedulerWithPriority:(TRSchedulerPriority)priority
{
    return (id<TRScheduler>)[RACQueueScheduler schedulerWithPriority:(RACSchedulerPriority)priority];
}

+ (id<TRScheduler>)scheduler
{
    return (id<TRScheduler>)[RACQueueScheduler scheduler];
}

+ (id<TRScheduler>)currentScheduler
{
    return (id<TRScheduler>)[RACQueueScheduler currentScheduler];
}

@end
