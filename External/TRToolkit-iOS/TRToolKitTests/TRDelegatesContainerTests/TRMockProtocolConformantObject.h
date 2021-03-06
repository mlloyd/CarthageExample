//
//  TRMockProtocolConformantObject.h
//  Chowderios
//
//  Created by Pedro Gomes on 04/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRMockProtocol.h"

@interface TRMockProtocolConformantObject : NSObject <TRMockProtocol>

@property (nonatomic, copy) dispatch_block_t onInvocationBlock;

@end
