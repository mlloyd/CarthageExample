//
//  UIDevice+TRAdditions.h
//  Chowderios
//
//  Created by Pedro Gomes on 13/12/2013.
//  Copyright (c) 2013 Thomson Reuters Global Resources. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface UIDevice(TRAdditions)

- (NSNumber *)totalDiskSpace;
- (NSNumber *)freeDiskSpace;

@end
