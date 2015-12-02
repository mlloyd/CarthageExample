//
//  TRDataStackManager.m
//  Chowderios
//
//  Created by Alex Skorulis on 27/08/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRDataStackManager.h"
#import "TRDelegateContainer.h"
#import "TRManagedObjectContextPool.h"
#import "TRLog.h"

NSString* const kCDWritingDidStartNotification = @"kCDWritingDidStartNotification";
NSString* const kCDWritingDidEndNotification = @"kCDWritingDidEndNotification";

NSString *const kTRDataStackManagerDataModelURLKey       = @"kTRDataStackManagerDataModelURLKey";
NSString *const kTRDataStackManagerPersistentStoreURLKey = @"kTRDataStackManagerPersistentStoreURLKey";
NSString *const kTRDataStackManagerPersistentStoreURLAttributeKey = @"kTRDataStackManagerPersistentStoreURLAttributeKey";

const NSUInteger kManagedObjectContextPoolSize = 4;

static TRDataStackManager* sharedObject;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRDataStackManager ()

@property (nonatomic, strong) NSManagedObjectContext* writingObjectContext;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, strong) TRManagedObjectContextPool *managedObjectContextPool;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation TRDataStackManager

@synthesize mainManagedObjectContext    = _mainManagedObjectContext;
@synthesize persistentStoreCoordinator  = _persistentStoreCoordinator;
@synthesize managedObjectModel          = _managedObjectModel;
@synthesize managedObjectContextPool    = _managedObjectContextPool;

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithConfiguration:(NSDictionary *)configuration
{
    NSParameterAssert(configuration[kTRDataStackManagerDataModelURLKey] != nil);
    NSParameterAssert(configuration[kTRDataStackManagerPersistentStoreURLKey] != nil);
    
    if((self = [super init])) {
        self.configuration = configuration;
        [self _setupContexts];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)temporaryContext
{
    NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [temporaryContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    temporaryContext.parentContext = self.mainManagedObjectContext;
    return temporaryContext;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)contextWithIdentifier:(id<NSCopying>)identifier
{
    return [self.managedObjectContextPool fetchContextWithIdentifier:identifier];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)flushContextPool
{
    [self.managedObjectContextPool flush];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [self _objectModelURL];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
        [self _createPersistentStore:TRUE];
    }
    
    return _persistentStoreCoordinator;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSString *)persistentStorePath
{
    const char* fileRep = [[self _persistentStoreURL] fileSystemRepresentation];
    
    return [NSString stringWithUTF8String:fileRep];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resetAllData
{
    TRLogInfo(TRLogContextStackManager, @"Deleting all application data...");
    
    [self tr_notifyDelegatesWithBlockAndWait:^(id delegate) {
        if([delegate respondsToSelector:@selector(dataStackManagerWillResetData:)]) {
            [delegate dataStackManagerWillResetData:self];
        }
    }];
    
    [self _deletePersistentStore];
    [self _createPersistentStore:TRUE];
    [self _setupContexts];
    
    [self tr_notifyDelegatesWithBlockAndWait:^(id delegate) {
        if([delegate respondsToSelector:@selector(dataStackManagerDidResetData:)]) {
            [delegate dataStackManagerDidResetData:self];
        }
    }];
    TRLogInfo(TRLogContextStackManager, @"Application data has been deleted.");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)cleanObject:(NSManagedObjectID*)objectID
{
    NSParameterAssert(objectID != nil);
    
    [self.mainManagedObjectContext performBlock:^{
        NSManagedObject* obj = [self.mainManagedObjectContext objectWithID:objectID];
        [self.mainManagedObjectContext refreshObject:obj mergeChanges:FALSE];
    }];
    [self.writingObjectContext performBlock:^{
        NSManagedObject* obj = [self.writingObjectContext objectWithID:objectID];
        [self.writingObjectContext refreshObject:obj mergeChanges:FALSE];
    }];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)saveToDiskFromContext:(NSManagedObjectContext *)context
            completionHandler:(TRStackManagerCompletionBlock)completionHandler
                 errorHandler:(TRStackManagerErrorBlock)errorHandler
{
    [self saveToDiskFromContext:context
              completionHandler:completionHandler
                   errorHandler:errorHandler
                           wait:NO];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)saveToDiskFromContext:(NSManagedObjectContext *)context
            completionHandler:(TRStackManagerCompletionBlock)block
                 errorHandler:(TRStackManagerErrorBlock)errorHandler
                         wait:(BOOL)wait
{
    if(context != self.mainManagedObjectContext) {
        if(wait) {
            [context performBlockAndWait:^{
                [self _saveToDiskFromContext:context
                           completionHandler:block
                                errorHandler:errorHandler];
            }];
        }
        else {
            [context performBlock:^{
                [self _saveToDiskFromContext:context
                           completionHandler:block
                                errorHandler:errorHandler];
            }];
        }
    }
    else {
        [self saveMainContext:wait
            completionHandler:block
                 errorHandler:errorHandler];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)saveMainContext:(BOOL)waitOnMain
      completionHandler:(TRStackManagerCompletionBlock)block
           errorHandler:(TRStackManagerErrorBlock)errorHandler
{
    if(waitOnMain) {
        [self.mainManagedObjectContext performBlockAndWait:^{
            [self _saveMainContextWithCompletionHandler:block
                                           errorHandler:errorHandler];
        }];
    }
    else {
        [self.mainManagedObjectContext performBlock:^{
            [self _saveMainContextWithCompletionHandler:block
                                           errorHandler:errorHandler];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)saveContext:(NSManagedObjectContext *)context error:(NSError __autoreleasing **)outError
{
    NSError *error = nil;
    if([context obtainPermanentIDsForObjects:[[context insertedObjects] allObjects] error:&error] == NO) {
        TRLogTrace(TRLogContextDefault, @"<error = %@>", error);
    }

    BOOL success = [context save:&error];
    if(success == NO) {
        if(outError != NULL) {
            *outError = error;
        }
        TRLogTrace(TRLogContextDefault, @"---> DataStackManager: saving for context %@ failed.\n"
              @"---> Errors:\n%@", context, error);
    }
    return success;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)objectExists:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context
{
    return ([context existingObjectWithID:objectID error:nil] != nil);
}

#pragma mark - Private Methods - Setup

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_setupContexts
{
    NSAssert(self.configuration[kTRDataStackManagerDataModelURLKey] != nil, @"configuration: data model url unexpectedly nil");
    NSAssert(self.configuration[kTRDataStackManagerPersistentStoreURLKey] != nil, @"configuration: persistent store url unexpectedly nil");
    
    _writingObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_writingObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    _writingObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_mainManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    _mainManagedObjectContext.parentContext = _writingObjectContext;
    
    _managedObjectContextPool = [[TRManagedObjectContextPool alloc] initWithPoolSize:kManagedObjectContextPoolSize stackManager:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_createPersistentStore:(BOOL)firstAttempt
{
    NSURL *storeURL = [self _persistentStoreURL];
    
    NSDictionary *options = @{ NSSQLitePragmasOption : @{ @"journal_mode" : @"DELETE" } };
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error]) {
        
        if(firstAttempt && error.code == 134100) {
            [self _deletePersistentStore];
            [self _createPersistentStore:FALSE];
        } else {
            TRLogTrace(TRLogContextDefault, @"Cannot handle error: %@, %@", error, [error userInfo]);
            abort();
        }
    }
    else {
        if(self.configuration[kTRDataStackManagerPersistentStoreURLAttributeKey] != nil) {
            BOOL success = [storeURL setResourceValue: [NSNumber numberWithBool: YES]
                                          forKey: self.configuration[kTRDataStackManagerPersistentStoreURLAttributeKey] error: &error];
            if(!success){
                TRLogTrace(TRLogContextDefault, @"Error setting atribute to %@ error: %@", [storeURL lastPathComponent], error);
            }
        }
        [self _databaseCreated];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_deletePersistentStore
{
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSURL *storeURL = [self _persistentStoreURL];
    
    NSError *error = nil;
    if([localFileManager removeItemAtURL:storeURL error:&error] == NO) {
        NSLog(@"error = %@", error);
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_databaseCreated
{
    //Empty method
}

#pragma mark - Private Methods - Saving

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_saveToDiskFromContext:(NSManagedObjectContext *)context
             completionHandler:(TRStackManagerCompletionBlock)block
                  errorHandler:(TRStackManagerErrorBlock)errorHandler
{
    NSError *error = nil;
    if([self saveContext:context error:&error] == YES) {
        [self saveMainContext:NO completionHandler:block errorHandler:errorHandler];
    }
    else {
        [self performErrorBlockOnMainThread:errorHandler withError:error];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_saveMainContextWithCompletionHandler:(TRStackManagerCompletionBlock)completionBlock
                                 errorHandler:(TRStackManagerErrorBlock)errorBlock
{
    __block NSError *error = nil;
    if([self saveContext:self.mainManagedObjectContext error:&error] == NO) {
        [self performErrorBlockOnMainThread:errorBlock withError:error];
        return;
    }
    
    if(self.writingObjectContext) {
        [self.writingObjectContext performBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kCDWritingDidStartNotification object:nil];
            if([self saveContext:self.writingObjectContext error:&error] == NO) {
                [self performErrorBlockOnMainThread:errorBlock withError:error];
            }
            else {
                [self performCompletionBlockOnMain:completionBlock];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kCDWritingDidEndNotification object:nil];
//            TRLogTrace(TRLogContextStackManager, @"Saved writing context. <registered_objects=%d>", [self.writingObjectContext registeredObjects].count);
//            [self.writingObjectContext reset];
//            TRLogTrace(TRLogContextStackManager, @"Saved writing context. <registered_objects=%d>", [self.writingObjectContext registeredObjects].count);
//            TRLogTrace(TRLogContextStackManager, @"Main Context. <registered_objects=%d>", [self.mainManagedObjectContext registeredObjects].count);
        }];
        [self.writingObjectContext performBlock:^{
//            TRLogTrace(TRLogContextStackManager, @"Saved writing context. <registered_objects=%d>", [self.writingObjectContext registeredObjects].count);
            [self.writingObjectContext reset];
//            TRLogTrace(TRLogContextStackManager, @"Saved writing context. <registered_objects=%d>", [self.writingObjectContext registeredObjects].count);
//            TRLogTrace(TRLogContextStackManager, @"Main Context. <registered_objects=%d>", [self.mainManagedObjectContext registeredObjects].count);
        }];
    }
    else {
        [self performCompletionBlockOnMain:completionBlock];
    }
}

#pragma mark - Private Methods - Misc

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performCompletionBlockOnMain:(void (^)())block
{
    if(!block) {return;}
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)performErrorBlockOnMainThread:(TRStackManagerErrorBlock)errorBlock withError:(NSError *)error
{
    if(errorBlock == nil) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        errorBlock(error);
    });
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSURL *)_persistentStoreURL
{
    return self.configuration[kTRDataStackManagerPersistentStoreURLKey];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSURL *)_objectModelURL
{
    return self.configuration[kTRDataStackManagerDataModelURLKey];
}

@end
