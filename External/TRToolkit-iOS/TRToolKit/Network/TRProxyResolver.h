//
//  TRProxyResolver.h
//  Chowderios
//
//  Created by Pedro Gomes on 18/03/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyResolverResult : NSObject

@property (nonatomic, readonly, copy) NSURL *resolvedURL;
@property (nonatomic, readonly, assign) BOOL needsProxyConfiguration;
@property (nonatomic, readonly, strong) NSArray *proxies;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyConfiguration : NSObject

@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly, copy) NSURL *proxyURL;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef void (^TRProxyResolverCompletionBlock)(TRProxyResolverResult *result);
typedef void (^TRProxyResolverErrorCallback)(NSError *error);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProxyResolver : NSObject

+ (instancetype)sharedResolver;

- (void)resolveURL:(NSURL *)URL
 completionHandler:(TRProxyResolverCompletionBlock)completionHandler
      errorHandler:(TRProxyResolverErrorCallback)errorHandler;

@end
