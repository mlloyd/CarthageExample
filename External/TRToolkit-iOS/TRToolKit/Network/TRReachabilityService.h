//
//  TRReachabilityService.h
//  TRFramework
//
//  Created by Pedro Gomes on 20/03/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(NSInteger, TRReachabilityServiceStatus) {
    TRReachabilityServiceStatusReachable   = 0,
    TRReachabilityServiceStatusUnreachable,
};

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class TRReachabilityService;
@protocol TRReachabilityServiceDelegate <NSObject>

- (void)reachabilityWithIdentifierDidChange:(NSString *)identifier status:(TRReachabilityServiceStatus)status;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extern NSString *const kTRReachabilityServiceIdentifierLocalWIFI;
extern NSString *const kTRReachabilityServiceIdentifierInternet;

extern NSString *const kTRReachabilityServiceDuplicateHostnameException;
extern NSString *const kTRReachabilityServiceInvalidHostnameException;
extern NSString *const kTRReachabilityServiceHostnameNotRegisteredException;
extern NSString *const kTRReachabilityServiceInvalidIdentifierException;
extern NSString *const kTRReachabilityServiceAlreadyRunningException;

////////////////////////////////////////////////////////////////////////////////
// Simply here to document the implemented UIApplicationDelegate methods
////////////////////////////////////////////////////////////////////////////////
@protocol TRReachabilityService <UIApplicationDelegate>

@property (nonatomic, readonly) NSArray *registeredIdentifiers;

- (void)start;
- (void)stop;

- (void)addHostname:(NSString *)hostname    __deprecated; // Deprecated, please use addHostname:withIdentifier: instead
- (void)removeHostname:(NSString *)hostname __deprecated; // Deprecated, please user removeHostnameForIdentifier: instead

- (void)addHostname:(NSString *)hostname withIdentifier:(NSString *)identifier;
- (void)removeHostnameForIdentifier:(NSString *)identifier;

- (void)registerDelegate:(id<TRReachabilityServiceDelegate>)delegate; // Registers delegate for all registered identifiers (@pedrogomes 21.03.2014)
- (void)registerDelegate:(id<TRReachabilityServiceDelegate>)delegate forIdentifier:(NSString *)identifier;
- (void)deregisterDelegate:(id<TRReachabilityServiceDelegate>)delegate;

- (TRReachabilityServiceStatus)statusForIdentifier:(NSString *)identifier;
- (BOOL)isReachable:(NSString *)identifier;

@end

////////////////////////////////////////////////////////////////////////////////
// The service conforms with UIApplicationDelegate, as it is meant to be instanciated
// on app start and should be forwarded all relevant UIApplicationDelegate methods from the
// application delegate
// Yes, we could simply register for the appropriate notifications, but this way is clearer (less magic) and more flexible
////////////////////////////////////////////////////////////////////////////////
@interface TRReachabilityService : NSObject <TRReachabilityService>

+ (TRReachabilityService *)sharedInstance;

@end
