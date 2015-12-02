//
//  TRProxyResolver.m
//  Chowderios
//
//  Created by Pedro Gomes on 18/03/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>

#import "TRProxyResolver.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyResolver ()

@property (nonatomic, strong) dispatch_queue_t workQueue;

- (TRProxyResolverResult *)_parseProxyConfigurationList:(NSArray *)proxies;

- (void)_reportCompletionWithResult:(TRProxyResolverResult *)result
                  completionHandler:(TRProxyResolverCompletionBlock)completionHandler;

- (void)_reportCompletionWithError:(NSError *)error
                      errorHandler:(TRProxyResolverErrorCallback)errorHandler;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyResolverContext : NSObject

@property (nonatomic, weak) TRProxyResolver *resolver;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) TRProxyResolverCompletionBlock completionHandlerBlock;
@property (nonatomic, copy) TRProxyResolverErrorCallback errorHandlerBlock;
@property (nonatomic, assign) CFRunLoopRef runLoop;
@property (nonatomic, assign) CFRunLoopSourceRef runLoopSource;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyResolverResult ()

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, assign) BOOL needsProxyConfiguration;
@property (nonatomic, strong) NSArray *proxies;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyConfiguration ()

@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSURL *proxyURL;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRProxyResolverContext
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRProxyConfiguration

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> proxy-type=%@; proxy-url=%@",
            NSStringFromClass([self class]),
            self,
            self.type,
            self.proxyURL];
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRProxyResolverResult
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void TRProxyResolverAutoConfigCallback(void *client, CFArrayRef proxyList, CFErrorRef error)
{
    TRProxyResolverContext *context = (__bridge_transfer TRProxyResolverContext *)client;
    
    CFRunLoopRemoveSource(context.runLoop, context.runLoopSource, kCFRunLoopDefaultMode);
    
    if(error != NULL) {
        NSError *__autoreleasing resultError = (__bridge NSError *)error;
        [context.resolver _reportCompletionWithError:resultError
                                        errorHandler:context.errorHandlerBlock];
    }
    else {
        NSArray *proxies = (__bridge NSArray *)proxyList;
        TRProxyResolverResult *result = [context.resolver _parseProxyConfigurationList:proxies];
        [context.resolver _reportCompletionWithResult:result
                                    completionHandler:context.completionHandlerBlock];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRProxyResolver

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (instancetype)sharedResolver
{
    static TRProxyResolver *resolver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resolver = [[TRProxyResolver alloc] init];
    });
    return resolver;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.workQueue = dispatch_queue_create("com.tr.toolkit.proxy-resolver", NULL);
    }
    return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resolveURL:(NSURL *)URL
 completionHandler:(TRProxyResolverCompletionBlock)completionHandler
      errorHandler:(TRProxyResolverErrorCallback)errorHandler
{
    NSURL *destinationURL = [self _convertToCompatibleSchemeIfNeeded:URL];
    
    NSDictionary *systemProxySettings = CFBridgingRelease(CFNetworkCopySystemProxySettings());
    NSArray *proxiesForURL = CFBridgingRelease(CFNetworkCopyProxiesForURL((__bridge CFURLRef)destinationURL,
                                                                          (__bridge CFDictionaryRef)systemProxySettings));
    NSDictionary *config = [proxiesForURL firstObject];
    
    BOOL supportsAutoConfiguration = ([config[(__bridge id)kCFProxyTypeKey] isEqualToString:(__bridge id)kCFProxyTypeAutoConfigurationURL]);
    if(supportsAutoConfiguration) {
        NSURL *autoConfigScriptURL = config[(__bridge id)kCFProxyAutoConfigurationURLKey];
        
        TRProxyResolverContext *resolverContext = [[TRProxyResolverContext alloc] init];
        resolverContext.resolver = self;
        resolverContext.URL = URL;
        resolverContext.completionHandlerBlock = completionHandler;
        resolverContext.errorHandlerBlock = errorHandler;

        CFStreamClientContext context = {0, (__bridge_retained void *)(resolverContext), NULL, NULL};
        
        CFRunLoopSourceRef runLoopSource = CFNetworkExecuteProxyAutoConfigurationURL((__bridge CFURLRef)autoConfigScriptURL,
                                                                                     (__bridge CFURLRef)destinationURL,
                                                                                     &TRProxyResolverAutoConfigCallback,
                                                                                     &context);
        resolverContext.runLoop = CFRunLoopGetCurrent();
        resolverContext.runLoopSource = runLoopSource;
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
        CFRelease(runLoopSource);
    }
    else {
        TRProxyResolverResult *resolverResult = [self _parseProxyConfigurationList:proxiesForURL];
        [self _reportCompletionWithResult:resolverResult
                        completionHandler:completionHandler];
    }
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_reportCompletionWithResult:(TRProxyResolverResult *)result completionHandler:(TRProxyResolverCompletionBlock)completionHandler
{
    if(completionHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(result);
        });
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_reportCompletionWithError:(NSError *)error errorHandler:(TRProxyResolverErrorCallback)errorHandler
{
    if(errorHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            errorHandler(error);
        });
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (TRProxyResolverResult *)_parseProxyConfigurationList:(NSArray *)proxies
{
    TRProxyResolverResult *result = [[TRProxyResolverResult alloc] init];
    
    NSMutableArray *resolvedProxies = [NSMutableArray array];
    for(NSDictionary *config in proxies) {
        BOOL proxyConfigurationRequired = ([config[(__bridge id)kCFProxyTypeKey] isEqualToString:(__bridge id)kCFProxyTypeNone] == NO);
        if(proxyConfigurationRequired == NO) {
            // if we already have proxy configurations, we ignore the 'kCFProxyTypeNone' type configuration (@pedrogomes 18.03.2014)
            if(resolvedProxies.count == 0) {
                result.needsProxyConfiguration = NO;
                break;
            }
            continue;
        }
        
        NSString *proxyType = config[(__bridge id)kCFProxyTypeKey];
        NSString *proxyHost = config[(__bridge id)kCFProxyHostNameKey];
        NSNumber *proxyPort = config[(__bridge id)kCFProxyPortNumberKey];
        NSString *scheme = [proxyType isEqualToString:(__bridge id)kCFProxyTypeHTTPS] ? @"https" : @"http";
        
        TRProxyConfiguration *proxyConfig = [[TRProxyConfiguration alloc] init];
        proxyConfig.type = proxyType;
        proxyConfig.proxyURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", scheme, proxyHost, proxyPort]];
        [resolvedProxies addObject:proxyConfig];
    }
    result.needsProxyConfiguration = (resolvedProxies.count > 0);
    result.proxies = [NSArray arrayWithArray:resolvedProxies];

    return result;
}

////////////////////////////////////////////////////////////////////////////////
// The underlying CFNetwork framework does not support ws/wss uri schemes
// so we need to convert them to http/https (@pedrogomes 18.03.2014)
////////////////////////////////////////////////////////////////////////////////
- (NSURL *)_convertToCompatibleSchemeIfNeeded:(NSURL *)URL
{
    NSString *scheme = [[URL scheme] lowercaseString];
    
    if([scheme isEqualToString:@"wss"]) {
        scheme = @"https";
    }
    else if ([scheme isEqualToString:@"ws"]) {
        scheme = @"http";
    }
    else {
        return URL;
    }
    
    NSString *URLString = ([URL port] ?
                           [NSString stringWithFormat:@"%@://%@:%@/", scheme, [URL host], [URL port]] :
                           [NSString stringWithFormat:@"%@://%@/", scheme, [URL host]]);
    return [NSURL URLWithString:URLString];
}

@end
