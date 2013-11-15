//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "NSObject+OCMAdditions.h"
#import "NSMethodSignature+OCMAdditions.h"
#import <objc/runtime.h>

static IMP InstanceMethodForwarderForSelector(id obj, SEL aSelector)
{
    // use NSSelectorFromString and not @selector to avoid warning
    SEL selectorWithNoImplementation = NSSelectorFromString(@"methodWhichMustNotExist::::");

#ifndef __arm64__
    NSMethodSignature *sig = [obj instanceMethodSignatureForSelector:aSelector];
    if([sig usesSpecialStructureReturn])
        return class_getMethodImplementation_stret(obj, selectorWithNoImplementation);
#endif

    return class_getMethodImplementation(obj, selectorWithNoImplementation);
}

@implementation NSObject(OCMAdditions)

+ (IMP)instanceMethodForwarderForSelector:(SEL)aSelector
{
    return InstanceMethodForwarderForSelector(self, aSelector);
}

@end

@implementation NSProxy(OCMAdditions)

+ (IMP)instanceMethodForwarderForSelector:(SEL)aSelector
{
    return InstanceMethodForwarderForSelector(self, aSelector);
}

@end