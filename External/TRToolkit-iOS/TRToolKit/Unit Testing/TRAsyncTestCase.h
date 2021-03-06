//
//  TRAsyncTestCase.h
//  Chowderios
//
//  Created by Pedro Gomes on 19/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XCTestCase+AsyncTesting.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRAsyncTestCase : XCTestCase

- (void)registerExpectedCallback:(id)callback;
- (void)signalCallbackReceived:(id)callback;

@end
