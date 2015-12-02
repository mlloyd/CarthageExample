//
//  TRUnitTestingHelper.h
//  TRToolKit
//
//  Created by Pedro Gomes on 20/02/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class TRDataStackManager;
@interface TRUnitTestingHelper : NSObject

+ (TRDataStackManager *)createDataStackManagerWithModelURL:(NSURL *)modelURL;

@end
