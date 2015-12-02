//
//  TRDelegateContainer.h
//  TRToolKit
//
//  Created by Pedro Gomes on 10/03/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import "TRDelegateProxy.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@compatibility_alias TRDelegateContainer TRDelegateProxy;
@interface NSObject (TRDelegateContainerDeprecated)

@property (nonatomic, readonly) TRDelegateContainer *delegateContainer DEPRECATED_ATTRIBUTE;

@end

#define TRDelegateContainerConformToProtocol(_protocolName_) \
@interface TRDelegateContainer(EB40AEB26C6B48349E84BB5AEEC722DA##_protocolName_) <_protocolName_> \
@end
