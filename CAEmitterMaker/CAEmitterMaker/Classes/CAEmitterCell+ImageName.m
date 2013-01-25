//
//  CAEmitterCell+ImageName.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/25/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "CAEmitterCell+ImageName.h"
#import <objc/runtime.h>

static char const * const kImageNameKey = "imageNameKey";

@implementation CAEmitterCell (ImageName)

- (void)setImageName:(NSString *)imageName
{
    objc_setAssociatedObject(self, kImageNameKey, imageName, OBJC_ASSOCIATION_COPY);
}

- (NSString *)imageName
{
    return objc_getAssociatedObject(self, kImageNameKey);
}

@end
