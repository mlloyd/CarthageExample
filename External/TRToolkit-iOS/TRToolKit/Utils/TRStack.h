//
//  TRStack.h
//  TRToolKit
//
//  Created by Pedro Gomes on 20/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRStack : NSObject <NSFastEnumeration>

- (instancetype)initWithCapacity:(NSUInteger)capacity;

- (void)push:(id)object;

- (id)pop;

- (id)top;

- (BOOL)isEmpty;

- (NSUInteger)count;

@end
