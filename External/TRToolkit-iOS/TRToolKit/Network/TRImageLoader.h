//
//  TRImageLoader.h
//  Gumbo
//
//  Created by Pedro Gomes on 27/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRImageLoader : NSObject

+ (instancetype)sharedLoader;

- (void)fetchImageWithURL:(NSURL *)imageURL
        completionHandler:(void (^)(UIImage *image))completion
             errorHandler:(void (^)(NSError *error))errorHandler;

- (void)fetchImageWithURL:(NSURL *)imageURL
            callbackQueue:(dispatch_queue_t)callbackQueue
        completionHandler:(void (^)(UIImage *))completion
             errorHandler:(void (^)(NSError *))errorHandler;

- (void)cancelRequestForImageWithURL:(NSURL *)imageURL;
- (void)cancelAllRequests;

@end
