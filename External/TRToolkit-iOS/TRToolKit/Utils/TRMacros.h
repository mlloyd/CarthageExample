//
//  TRMacros.h
//  Chowderios
//
//  Created by Pedro Gomes on 19/02/2014.
//  Copyright (c) 2014 Thomson Reuters Global Resources.  All Rights Reserved.  Proprietary and confidential information of TRGR.  Disclosure, use, or reproduction without written authorization of TRGR is prohibited. All rights reserved.
//

#ifndef Chowderios_TRMacros_h
#define Chowderios_TRMacros_h

#define TR_RETURN_IF(condition) if(condition) { return; }

#define TR_RETURN_UNLESS(condition) if(!(condition)) { return; }
#define TR_RETURN_FALSE_UNLESS(condition) if(!(condition)) { return NO; }
#define TR_RETURN_NIL_UNLESS(condition) if(!(condition)) { return nil; }

#endif
