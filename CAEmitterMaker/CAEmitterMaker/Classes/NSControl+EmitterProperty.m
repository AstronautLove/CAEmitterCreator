//
//  NSControl+EmitterProperty.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/16/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "NSControl+EmitterProperty.h"
#import <objc/runtime.h>

static char const * const kPropertyKey = "emitterPropertyKey";

@implementation NSControl (EmitterProperty)

- (void) setEmitterPropertyToModify:(NSString *) aProperty
{
    objc_setAssociatedObject(self, kPropertyKey, aProperty, OBJC_ASSOCIATION_COPY);
}

- (NSString *) emitterPropertyToModify
{
    return objc_getAssociatedObject(self, kPropertyKey);
}

@end
