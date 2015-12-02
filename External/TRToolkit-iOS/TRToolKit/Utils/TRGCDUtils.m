//
//  TRCGDUtils.m
//  Chowderios
//
//  Created by Pedro Gomes on 11/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import "TRGCDUtils.h"

////////////////////////////////////////////////////////////////////////////////
// The purpose of this method is to ensure the submitted block doesn't cause
// a deadlock on the main queue
////////////////////////////////////////////////////////////////////////////////
void
dispatch_main_sync_reentrant(dispatch_block_t block)
{
    if([[NSThread currentThread] isMainThread]) {
        block();
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
