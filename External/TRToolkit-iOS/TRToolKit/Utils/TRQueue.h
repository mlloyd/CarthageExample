//
//  TRQueue.h
//  TRToolKit
//
//  Created by Pedro Gomes on 07/03/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRQueue : NSObject

- (instancetype)initWithObject:(id)object;
- (instancetype)initWithArray:(NSArray *)array;

- (void)enqueue:(id)object;
- (id)dequeue;

- (id)top;

- (NSUInteger)size;
- (BOOL)isEmpty;

@end
