//
//  TRStateTransition.h
//  Chowderios
//
//  Created by Pedro Gomes on 06/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRStateTransitionProtocol.h"

static NSString *const kEventUserSignedIn            = @"kEventUserSignedIn";
static NSString *const kEventUserSignedOut           = @"kEventUserSignedOut";
static NSString *const kEventConnectionOnline        = @"kEventConnectionOnline";
static NSString *const kEventConnectionOffline       = @"kEventConnectionOffline";
static NSString *const kEventApplicationBackground   = @"kEventApplicationBackground";
static NSString *const kEventApplicationForeground   = @"kEventApplicationForeground";
static NSString *const kEventApplicationTerminate    = @"kEventApplicationTerminate";
static NSString *const kEventDeleteCaches            = @"kEventDeleteCaches";
static NSString *const kEventDeleteCachesCompleted   = @"kEventDeleteCachesCompleted";
static NSString *const kEventServicesStarted         = @"kEventServicesStarted";
static NSString *const kEventInitialDataAvailable    = @"kEventInitialDataAvailable";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRStateTransition : NSObject <TRStateTransition>

- (instancetype)initWithIdentifier:(NSString *)identifier;

@end
