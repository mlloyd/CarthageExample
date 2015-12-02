//
//  TRMockProtocolPartiallyConformantObject.m
//  Chowderios
//
//  Created by Pedro Gomes on 04/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRMockProtocolPartiallyConformantObject.h"

@implementation TRMockProtocolPartiallyConformantObject 

+ (void)mockRequiredClassMethod
{
//    TRLogTrace(TRLogContextDefault, @"[%@ (%p)]: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd));
}

- (void)mockRequiredMethod
{
//    TRLogTrace(TRLogContextDefault, @"[%@ (%p)]: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd));

    [self _callback];
}

- (void)mockRequiredMethodWithObject:(id)arg1
{
//    TRLogTrace(TRLogContextDefault, @"[%@ (%p)]: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd));

    [self _callback];
}

- (void)mockRequiredMethodWithObject:(id)arg1 andObject:(id)arg2
{
//    TRLogTrace(TRLogContextDefault, @"[%@ (%p)]: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd));

    [self _callback];
}

- (NSString *)mockOptionalInstanceMethodWithNonVoidReturnType
{
//    TRLogTrace(TRLogContextDefault, @"[%@ (%p)]: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd));
    
    return [NSString stringWithFormat:@"%@ (%p)", NSStringFromClass([self class]), self] ;
}

- (void)_callback
{
    if(self.onInvocationBlock) {
        self.onInvocationBlock();
    }
}

@end
