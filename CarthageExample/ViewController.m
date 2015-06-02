//
//  ViewController.m
//  CarthageExample
//
//  Created by Martin Lloyd on 28/05/2015.
//  Copyright (c) 2015 Thomson Reuters. All rights reserved.
//

#import "ViewController.h"

#import <WebImage/WebImage.h>
#import <Aspects/Aspects.h>
#import <Objection/Objection.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    JSObjectionInjector *defaultObjection = [JSObjection defaultInjector];
    defaultObjection = nil;
}

@end
