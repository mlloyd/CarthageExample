//
//  TRImageLoader.m
//  Gumbo
//
//  Created by Pedro Gomes on 27/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import "TRImageLoader.h"
#import "TRMacros.h"
#import "TRVerify.h"

static TRImageLoader *_imageLoader = nil;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRImageLoader ()

@property (nonatomic, strong) dispatch_queue_t lockQueue;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary *tasks;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRImageLoader

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (instancetype)sharedLoader
{
    if(_imageLoader == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _imageLoader = [[[self class] alloc] init];
        });
    }
    
    return _imageLoader;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    if((self = [super init])) {
        self.session = [NSURLSession sharedSession];
        self.tasks = [NSMutableDictionary dictionary];
        self.lockQueue = dispatch_queue_create("com.tr.toolkit.image-loader", NULL);
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)fetchImageWithURL:(NSURL *)imageURL
        completionHandler:(void (^)(UIImage *image))completion
             errorHandler:(void (^)(NSError *error))errorHandler
{
    [self fetchImageWithURL:imageURL
              callbackQueue:dispatch_get_main_queue()
          completionHandler:completion
               errorHandler:errorHandler];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)fetchImageWithURL:(NSURL *)imageURL
            callbackQueue:(dispatch_queue_t)callbackQueue
        completionHandler:(void (^)(UIImage *))completion
             errorHandler:(void (^)(NSError *))errorHandler

{
    TR_RETURN_UNLESS(imageURL != nil);
    TR_RETURN_UNLESS(self.tasks[imageURL] == nil);

    if(TRVerify(callbackQueue != NULL, @"callbackQueue != NULL not satisfied") == NO) {
        return;
    };

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_sync(weakSelf.lockQueue, ^{
            [weakSelf.tasks removeObjectForKey:imageURL];
        });
        if(error == nil) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_sync(callbackQueue, ^{ completion(image); });
        }
        else {
            dispatch_sync(callbackQueue, ^{ errorHandler(error); });
        }
    }];
    
    self.tasks[imageURL] = task;
    [task resume];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)cancelRequestForImageWithURL:(NSURL *)imageURL
{
    TR_RETURN_UNLESS(self.tasks[imageURL] != nil);

    NSURLSessionDataTask *task = self.tasks[imageURL];
    [task cancel];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)cancelAllRequests
{
    [[self.tasks allValues] makeObjectsPerformSelector:@selector(cancel)];
}

@end
