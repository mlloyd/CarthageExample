//
//  TRVerify.h
//  Chowderios
//
//  Created by Matt Evans on 04/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#ifndef Chowderios_TRAssert_h
#define Chowderios_TRAssert_h

/*
Usage: TRVerify(expression, @"message")
---------------------------------------
In debug builds, TRVerify evaluates the expression, asserts the result and then returns the result.
In non-debug builds, TRVerify returns the result of evaluating the expression.

Use cases:
----------
if(TRVerify(some expression, @"error message")) {
    // do something that relies on the expression being true;
}
 
Or:
 
SomeType value = TRVerify(some expression, @"error message");
// in debug, this asserts a return value inline, retaining the type of expression.
 
Advantages:
-----------
Allows recovery from the asserted condition in release, where feasible
AND makes it easier to write return value asserts in one line (using the inline form).
*/

#if !defined(NS_BLOCK_ASSERTIONS)
#define TRVerify(x, msg) ({ typeof(((x))) tmp = ((x)); NSAssert(tmp, msg); tmp; })
#else
#define TRVerify(x, msg) ((x))
#endif

#endif
