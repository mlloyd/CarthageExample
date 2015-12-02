//
//  TRReachabilityService.m
//  TRFramework
//
//  Created by Pedro Gomes on 20/03/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TRReachabilityService.h"
#import "TRReachability.h"
#import "TRDelegateProxy.h"
#import "TRLog.h"

TRDelegateProxyConformToProtocol(TRReachabilityServiceDelegate);

////////////////////////////////////////////////////////////////////////////////
// Constants and definitions
////////////////////////////////////////////////////////////////////////////////
NSString *const kTRReachabilityServiceIdentifierLocalWIFI  = @"com.tr.toolkit.kTRReachabilityServiceIdentifierLocalWIFI";
NSString *const kTRReachabilityServiceIdentifierInternet   = @"com.tr.toolkit.kTRReachabilityServiceIdentifierInternet";

NSString *const kTRReachabilityServiceDuplicateHostnameException       = @"com.tr.toolkit.ReachabilityServce.DuplicateHostnameException";
NSString *const kTRReachabilityServiceInvalidHostnameException         = @"com.tr.toolkit.ReachabilityServce.InvalidHostnameException";
NSString *const kTRReachabilityServiceHostnameNotRegisteredException   = @"com.tr.toolkit.ReachabilityServce.HostnameNotRegisteredException";
NSString *const kTRReachabilityServiceInvalidIdentifierException       = @"com.tr.toolkit.ReachabilityServce.InvalidIdentifierException";
NSString *const kTRReachabilityServiceAlreadyRunningException          = @"com.tr.toolkit.ReachabilityService.ServiceAlreadyRunningException";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRReachabilityService()

@property (nonatomic, strong) dispatch_queue_t lockQueue;
@property (nonatomic, assign) BOOL serviceIsRunning;
@property (nonatomic, strong) NSHashTable *autoRegisteredDelegates;
@property (nonatomic, strong) NSMutableDictionary *delegatesByIdentifier;
@property (nonatomic, strong) NSMutableDictionary *reachabilityNotifiers;
@property (nonatomic, strong) NSMutableDictionary *reachabilityStatusCache;
@property (nonatomic, strong) NSArray *registeredIdentifiers;

- (void)_processReachabilityChangedNotification:(NSNotification *)notification;
- (void)_notifyDelegatesOfReachabilityChangeAndUpdateCacheForIdentifier:(NSString *)identifier isReachable:(BOOL)isReachable;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRReachabilityService

@dynamic registeredIdentifiers;

#pragma mark - Singleton

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (TRReachabilityService *)sharedInstance
{
    static TRReachabilityService *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[[self class] alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [self stop];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    if((self = [super init])) {
        self.lockQueue = dispatch_queue_create("com.ef.TR.TRReachabilityServiceLockQueue", NULL);
        
        self.autoRegisteredDelegates    = [NSHashTable weakObjectsHashTable];
        self.reachabilityNotifiers      = [NSMutableDictionary dictionary];
        self.reachabilityStatusCache    = [NSMutableDictionary dictionary];
        self.delegatesByIdentifier      = [NSMutableDictionary dictionary];
        
        TRReachability *wifiConnectionReachability        = [TRReachability reachabilityForLocalWiFi];
        TRReachability *internetConnectionReachability    = [TRReachability reachabilityForInternetConnection];
        
        wifiConnectionReachability.key      = kTRReachabilityServiceIdentifierLocalWIFI;
        internetConnectionReachability.key  = kTRReachabilityServiceIdentifierInternet;
        
        self.reachabilityNotifiers[kTRReachabilityServiceIdentifierLocalWIFI] = wifiConnectionReachability;
        self.reachabilityNotifiers[kTRReachabilityServiceIdentifierInternet]  = internetConnectionReachability;
        
        self.reachabilityStatusCache[kTRReachabilityServiceIdentifierLocalWIFI] = @([self checkReachabilityForIdentifier:kTRReachabilityServiceIdentifierLocalWIFI]);
        self.reachabilityStatusCache[kTRReachabilityServiceIdentifierInternet]  = @([self checkReachabilityForIdentifier:kTRReachabilityServiceIdentifierInternet]);
        
        self.delegatesByIdentifier[kTRReachabilityServiceIdentifierLocalWIFI] = [[TRDelegateProxy alloc] initWithProtocol:@protocol(TRReachabilityServiceDelegate)];
        self.delegatesByIdentifier[kTRReachabilityServiceIdentifierInternet]  = [[TRDelegateProxy alloc] initWithProtocol:@protocol(TRReachabilityServiceDelegate)];
    }
    return self;
}

#pragma mark - Properties

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)registeredIdentifiers
{
    __block NSArray *identifiers = nil;
    dispatch_sync(self.lockQueue, ^{
        identifiers = [self.reachabilityNotifiers allKeys];
    });
    return identifiers;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)start
{
    dispatch_sync(self.lockQueue, ^{
        if(self.serviceIsRunning == YES) {
            [[NSException exceptionWithName:kTRReachabilityServiceAlreadyRunningException
                                    reason:@"TRReachabilityService is already running"
                                  userInfo:nil] raise];
        }
        
        TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: starting...", self);
        [self.reachabilityNotifiers enumerateKeysAndObjectsUsingBlock:^(NSString *key, TRReachability *reachability, BOOL *stop) {
            
            BOOL isReachable = [self checkReachabilityForIdentifier:key];
            BOOL cachedReachabilityValue = [self.reachabilityStatusCache[key] boolValue];
            BOOL reachabilityHasChanged = (cachedReachabilityValue != isReachable);
            if(reachabilityHasChanged) {
                TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: reachability for <%@> has changed since the service was last stopped.>", self, key);
                [self _notifyDelegatesOfReachabilityChangeAndUpdateCacheForIdentifier:key
                                                                          isReachable:isReachable];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_processReachabilityChangedNotification:)
                                                         name:kTRReachabilityChangedNotification
                                                       object:reachability];
            [reachability startNotifier];
            TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: monitoring (%@)...>", self, reachability.key);
        }];
        self.serviceIsRunning = YES;
        TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: started.", self);
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)stop
{
    dispatch_sync(self.lockQueue, ^{
        if(self.serviceIsRunning) {
            TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: stopping...", self);
            [self.reachabilityNotifiers enumerateKeysAndObjectsUsingBlock:^(id key, TRReachability *reachability, BOOL *stop) {
                [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                name:kTRReachabilityChangedNotification
                                                              object:reachability];
                [reachability stopNotifier];
            }];
            self.serviceIsRunning = NO;
            TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: stopped.", self);
        }
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)addHostname:(NSString *)hostname
{
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[hostname] != nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceDuplicateHostnameException
                                     reason:[NSString stringWithFormat:@"Hostname <%@> was already registered.", hostname]
                                   userInfo:nil] raise];
        }
        
        TRReachability *reachability = [TRReachability reachabilityWithHostName:hostname];
        reachability.key = hostname;
        self.delegatesByIdentifier[reachability.key] = [[TRDelegateProxy alloc] initWithProtocol:@protocol(TRReachabilityServiceDelegate)];
        self.reachabilityNotifiers[reachability.key] = reachability;
        
        dispatch_async(self.lockQueue, ^{
            // reachability.isReachable is a blocking (and potentially long running operation) (pdcgomes 23.01.2013)
            self.reachabilityStatusCache[hostname] = @([self checkReachabilityForIdentifier:reachability.key]);
        });
//        [self.reachabilityStatusCache setObject:[NSNumber numberWithBool:reachability.isReachable] forKey:hostname];
        
        if(self.serviceIsRunning) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_processReachabilityChangedNotification:)
                                                         name:kTRReachabilityChangedNotification
                                                       object:reachability];
            [reachability startNotifier];
            TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: started monitoring (%@)...>", self, reachability.key);
        }
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)removeHostname:(NSString *)hostname
{
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[hostname] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceHostnameNotRegisteredException
                                     reason:[NSString stringWithFormat:@"Hostname <%@> wasn't previously registered.", hostname]
                                   userInfo:nil] raise];
        }
        
        TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: stopped monitoring (%@)...>", self, hostname);
        TRReachability *reachability = self.reachabilityNotifiers[hostname];
        if(self.serviceIsRunning == YES) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:kTRReachabilityChangedNotification
                                                          object:reachability];
            [reachability stopNotifier];
        }
        [self.delegatesByIdentifier removeObjectForKey:hostname];
        [self.reachabilityNotifiers removeObjectForKey:hostname];
        [self.reachabilityStatusCache removeObjectForKey:hostname];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)addHostname:(NSString *)hostname withIdentifier:(NSString *)identifier
{
    NSURL *hostURL = [NSURL URLWithString:hostname];
    if(hostURL == nil) {
        [[NSException exceptionWithName:kTRReachabilityServiceInvalidHostnameException
                                 reason:[NSString stringWithFormat:@"The provided hostname <%@> is invalid", hostname]
                               userInfo:nil] raise];
    }

    NSString *host = [hostURL host];

    BOOL originalHostnameContainsScheme = (nil != host);
    if (!originalHostnameContainsScheme) {
        host = hostname;
    }
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[identifier] != nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceDuplicateHostnameException
                                     reason:[NSString stringWithFormat:@"Hostname with identifier <%@> was already registered.", identifier]
                                   userInfo:nil] raise];
        }
        
        TRReachability *reachability = [TRReachability reachabilityWithHostName:host];
        reachability.key = identifier;
        self.delegatesByIdentifier[identifier]   = [[TRDelegateProxy alloc] initWithProtocol:@protocol(TRReachabilityServiceDelegate)];
        self.reachabilityNotifiers[identifier]   = reachability;
        self.reachabilityStatusCache[identifier] = @(NO);
        
        // Global delegates will be automatically registered for the new identifier (@pedrogomes 21.03.2014)
        for(id<TRReachabilityServiceDelegate> delegate in self.autoRegisteredDelegates) {
            [self registerDelegate:delegate forIdentifier:identifier];
        }

        dispatch_async(self.lockQueue, ^{
            self.reachabilityStatusCache[identifier] = @([self checkReachabilityForIdentifier:reachability.key]);
        });

        if(self.serviceIsRunning) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_processReachabilityChangedNotification:)
                                                         name:kTRReachabilityChangedNotification
                                                       object:reachability];
            [reachability startNotifier];
            TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: started monitoring (%@)...>", self, identifier);
        }
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)removeHostnameForIdentifier:(NSString *)identifier
{
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceHostnameNotRegisteredException
                                     reason:[NSString stringWithFormat:@"Hostname with identifier <%@> wasn't previously registered.", identifier]
                                   userInfo:nil] raise];
        }
        
        TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: stopped monitoring (%@)...>", self, identifier);
        
        TRReachability *reachability = self.reachabilityNotifiers[identifier];
        if(self.serviceIsRunning) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:kTRReachabilityChangedNotification
                                                          object:reachability];
            [reachability stopNotifier];
        }
        [self.delegatesByIdentifier removeObjectForKey:identifier];
        [self.reachabilityNotifiers removeObjectForKey:identifier];
        [self.reachabilityStatusCache removeObjectForKey:identifier];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerDelegate:(id<TRReachabilityServiceDelegate>)delegate
{
    dispatch_sync(self.lockQueue, ^{
        [self.delegatesByIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *key, TRDelegateProxy *delegateProxy, BOOL *stop) {
//            TRLogTrace(TRLogContextDefault, @"Registering delegate <%@> for identifier <%@>...", delegate, key);
            [delegateProxy registerDelegate:delegate];
        }];
        [self.autoRegisteredDelegates addObject:delegate];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)registerDelegate:(id<TRReachabilityServiceDelegate>)delegate forIdentifier:(NSString *)identifier
{
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceInvalidIdentifierException
                                     reason:[NSString stringWithFormat:@"Reachability identifier <%@> wasn't previously registered.", identifier]
                                   userInfo:nil] raise];
        }

        if(self.delegatesByIdentifier[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceInvalidIdentifierException
                                     reason:[NSString stringWithFormat:@"Reachability identifier <%@> wasn't previously registered.", identifier]
                                   userInfo:nil] raise];
        }
//        TRLogTrace(TRLogContextDefault, @"Registering delegate <%@> for identifier <%@>...", delegate, identifier);
        [self.delegatesByIdentifier[identifier] registerDelegate:delegate];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterDelegate:(id<TRReachabilityServiceDelegate>)delegate
{
    dispatch_sync(self.lockQueue, ^{
        [self.delegatesByIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *key, TRDelegateProxy *delegateProxy, BOOL *stop) {
            [delegateProxy deregisterDelegate:delegate];
//            TRLogTrace(TRLogContextDefault, @"Deregistering delegate <%@> for identifier <%@>...", delegate, key);
        }];
        [self.autoRegisteredDelegates removeObject:delegate];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)deregisterDelegate:(id<TRReachabilityServiceDelegate>)delegate forIdentifier:(NSString *)identifier
{
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceInvalidIdentifierException
                                     reason:[NSString stringWithFormat:@"Reachability identifier <%@> wasn't previously registered.", identifier]
                                   userInfo:nil] raise];
        }
        
        if(self.delegatesByIdentifier[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceInvalidIdentifierException
                                     reason:[NSString stringWithFormat:@"Delegate <%@> wasn't previously registered for identifier <%@>.", delegate, identifier]
                                   userInfo:nil] raise];
        }
        [self.delegatesByIdentifier[identifier] deregisterDelegate:delegate];
//            TRLogTrace(TRLogContextDefault, @"Deregistering delegate <%@> for identifier <%@>...", delegate, identifier);
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (TRReachabilityServiceStatus)statusForIdentifier:(NSString *)identifier
{
    BOOL __block isReachable = NO;
    dispatch_sync(self.lockQueue, ^{
        if(self.reachabilityNotifiers[identifier] == nil) {
            [[NSException exceptionWithName:kTRReachabilityServiceInvalidIdentifierException
                                     reason:[NSString stringWithFormat:@"Reachability identifier <%@> wasn't previously registered.", identifier]
                                   userInfo:nil] raise];
        }
        isReachable = [self checkReachabilityForIdentifier:identifier];
    });
    
    return (isReachable == YES ?
            TRReachabilityServiceStatusReachable :
            TRReachabilityServiceStatusUnreachable);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)isReachable:(NSString *)identifier
{
    return ([self statusForIdentifier:identifier] == TRReachabilityServiceStatusReachable);
}

#pragma mark - UIApplicationDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self start];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self stop];
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_processReachabilityChangedNotification:(NSNotification *)notification
{
    TRReachability *reachability = notification.object;
    NSString *identifier = reachability.key;
    
    TRLogTrace(TRLogContextDefault, @"<reachability: (%p) :: status for (%@ - %@) changed.>", self, identifier, reachability.description);
    dispatch_sync(self.lockQueue, ^{
        if(self.delegatesByIdentifier[identifier] == nil) {
            TRLogWarn(TRLogContextDefault, @"<reachability: (%p) :: no registered delegates for reachability service with identifier (%@).>", self, identifier);
            // No delegates are currently registered for this reachability, we can simply bail out
            return;
        }

        [self _notifyDelegatesOfReachabilityChangeAndUpdateCacheForIdentifier:identifier
                                                                  isReachable:[self checkReachabilityForIdentifier:identifier]];
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_notifyDelegatesOfReachabilityChangeAndUpdateCacheForIdentifier:(NSString *)identifier isReachable:(BOOL)isReachable
{
    TRReachabilityServiceStatus status = isReachable ? TRReachabilityServiceStatusReachable : TRReachabilityServiceStatusUnreachable;

    // We ensure that the delegate method gets called on a queue other then the queue that      //
    // called this method since it is possible (this has happened) that the delegate method     //
    // will call a method of this class which in turn dispatches a block of code synchronously. //
    // This senerio coupled with synchronous dispatch calls creates a dead-lock condition.      //
    // The dispatch to another queue breaks this dead-lock condition because it allows the      //
    // initial synchronous block to return immediately.                                         //
    dispatch_async(dispatch_get_main_queue(), ^{
        TRDelegateProxy *delegateProxy = self.delegatesByIdentifier[identifier];
        [delegateProxy reachabilityWithIdentifierDidChange:identifier status:status];
    });
    
    // Update the cache
    self.reachabilityStatusCache[identifier] = @(isReachable);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)checkReachabilityForIdentifier:(NSString *)identifier
{
    BOOL isReachable = ([identifier isEqualToString:kTRReachabilityServiceIdentifierLocalWIFI]) ?
    [self.reachabilityNotifiers[identifier] isReachableViaWiFi]:
    [self.reachabilityNotifiers[identifier] isReachable];
    
    return isReachable;
}

@end
