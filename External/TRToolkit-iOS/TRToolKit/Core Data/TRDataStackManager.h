//
//  TRDataStackManager.h
//  Chowderios
//
//  Created by Alex Skorulis on 27/08/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
extern NSString *const kCDWritingDidStartNotification;
extern NSString *const kCDWritingDidEndNotification;

extern NSString *const kTRDataStackManagerDataModelURLKey;
extern NSString *const kTRDataStackManagerPersistentStoreURLKey;
extern NSString *const kTRDataStackManagerPersistentStoreURLAttributeKey;

typedef void (^TRStackManagerCompletionBlock)(void);
typedef void (^TRStackManagerErrorBlock)(NSError *error);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRDataStackManagerProtocol;
@protocol TRDataStackManagerDelegate

@optional

- (void)dataStackManagerWillResetData:(id<TRDataStackManagerProtocol>)stackManager;
- (void)dataStackManagerDidResetData:(id<TRDataStackManagerProtocol>)stackManager;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol TRDataStackManagerProtocol <NSObject>

@property (nonatomic, strong) NSManagedObjectContext *mainManagedObjectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration;

- (void)tr_registerDelegate:(id<TRDataStackManagerDelegate>)delegate;
- (void)tr_deregisterDelegate:(id<TRDataStackManagerDelegate>)delegate;

- (NSManagedObjectContext *)temporaryContext;
- (NSManagedObjectContext *)contextWithIdentifier:(id<NSCopying>)identifier;
- (void)flushContextPool;

/*
 * A note on waiting: This will cause the method not to return until the FIRST save is complete. This will not wait on subsequent saves.
 * The purpose of this is so that you can save in a background thread and be assured that the merge into main is complete before notifying
 * listeners that you are finished.
 * The completion block will be called after the save is written to disk.
 */
- (void)saveToDiskFromContext:(NSManagedObjectContext *)context
            completionHandler:(TRStackManagerCompletionBlock)completionHandler
                 errorHandler:(TRStackManagerErrorBlock)errorHandler;

- (void)saveToDiskFromContext:(NSManagedObjectContext *)context
            completionHandler:(TRStackManagerCompletionBlock)block
                 errorHandler:(TRStackManagerErrorBlock)errorHandler
                         wait:(BOOL)wait;

- (void)saveMainContext:(BOOL)waitOnMain
      completionHandler:(TRStackManagerCompletionBlock)block
           errorHandler:(TRStackManagerErrorBlock)errorHandler;


- (void)cleanObject:(NSManagedObjectID *)objectID;
- (void)resetAllData; //Doing this will wipe all data

- (NSString *)persistentStorePath;

- (BOOL)objectExists:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRDataStackManager : NSObject <TRDataStackManagerProtocol>
@end

@compatibility_alias ChowderDataStackManager TRDataStackManager;
