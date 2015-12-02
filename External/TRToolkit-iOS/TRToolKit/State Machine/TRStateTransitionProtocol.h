//
//  TRTransitionProtocol.h
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TRDeclareStateTransition(_identifier_) [TRStateTransition transitionWithIdentifier:_identififier_]

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRState;
@protocol TRStateTransition <NSObject, NSCopying>

@property (nonatomic, copy, readonly) NSString *identifier;

+ (instancetype)transitionWithIdentifier:(NSString *)identifier;

@optional

+ (instancetype)transitionWithIdentifier:(NSString *)identifier
                                 toState:(id<TRState>)toState;



@end
