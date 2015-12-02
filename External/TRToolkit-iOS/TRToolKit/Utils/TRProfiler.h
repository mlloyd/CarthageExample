//
//  TRProfiler.h
//  TRToolKit
//
//  Created by Pedro Gomes on 18/03/2014.
//  Copyright (c) 2014 Thomson Reuters. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define TRProfileStart(__SESSION__) [TRProfiler start:__SESSION__]
#define TRProfileEnd(__SESSION__) [[TRProfiler session:__SESSION__] total];[TRProfiler finish:__SESSION__]
#else
#define TRProfileStart(__SESSION__) do {} while (0)
#define TRProfileEnd(__SESSION__) do {} while (0)
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface TRProfiler : NSObject

@end
