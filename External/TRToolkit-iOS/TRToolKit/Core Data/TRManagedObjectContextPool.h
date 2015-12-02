//
//  TRManagedObjectContextPool.h
//  Chowderios
//
//  Created by Pedro Gomes on 31/01/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRDataStackManagerProtocol;
@interface TRManagedObjectContextPool : NSObject

- (instancetype)initWithPoolSize:(NSUInteger)size stackManager:(id<TRDataStackManagerProtocol>)stackManager;
- (instancetype)initWithPoolSize:(NSUInteger)size lifetime:(NSTimeInterval)lifetime stackManager:(id<TRDataStackManagerProtocol>)stackManager;

- (NSManagedObjectContext *)fetchContextWithIdentifier:(id<NSCopying>)identifier;
- (void)flush;

@end
