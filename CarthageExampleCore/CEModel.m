//
//  CEModel.m
//  CarthageExample
//
//  Created by Martin Lloyd on 28/05/2015.
//  Copyright (c) 2015 Thomson Reuters. All rights reserved.
//

#import <Masonry/Masonry.h>

#import "CEModel.h"

@implementation CEModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        if ([MASViewAttribute class]) {
            // class exists
            MASViewAttribute *instance = [[MASViewAttribute alloc] init];
        } else {
            // class doesn't exist
        }
    }
    return self;
}

@end
