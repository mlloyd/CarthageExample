//
//  TRCGDUtils.h
//  Chowderios
//
//  Created by Pedro Gomes on 11/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
// The purpose of this method is to ensure the submitted block doesn't cause
// a deadlock on the main queue
////////////////////////////////////////////////////////////////////////////////
extern void dispatch_main_sync_reentrant(dispatch_block_t block);
