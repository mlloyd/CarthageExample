//
//  TRDisposable.m
//  TRToolKit
//
//  Created by Pedro Gomes on 21/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "TRDisposable.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRDisposable

+ (instancetype)disposableWithBlock:(void (^)(void))block
{
    return (id<TRDisposable>)[RACDisposable disposableWithBlock:block];
}

@end
